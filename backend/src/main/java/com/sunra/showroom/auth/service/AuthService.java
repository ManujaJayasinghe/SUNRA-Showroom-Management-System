package com.sunra.showroom.auth.service;

import com.sunra.showroom.auth.dto.AuthResponse;
import com.sunra.showroom.auth.dto.ChangePasswordRequest;
import com.sunra.showroom.auth.dto.LoginRequest;
import com.sunra.showroom.auth.dto.UserSummaryDto;
import com.sunra.showroom.auth.exception.AccountDeactivatedException;
import com.sunra.showroom.auth.exception.AccountLockedException;
import com.sunra.showroom.auth.security.JwtTokenProvider;
import com.sunra.showroom.auth.security.SecurityUtils;
import com.sunra.showroom.auth.security.UserPrincipal;
import com.sunra.showroom.common.db.DbSessionContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final DbSessionContext dbSessionContext;

    public AuthResponse login(LoginRequest request) {
        LoginUserRecord user = loadLoginUser(request.username());

        if (user == null) {
            log.warn("Login failed: username '{}' not found", request.username());
            throw new BadCredentialsException("Invalid username or password");
        }

        if (!user.active()) {
            log.warn("Login rejected: user '{}' is deactivated", request.username());
            throw new AccountDeactivatedException("Account is deactivated. Please contact an administrator.");
        }

        if (user.lockedUntil() != null && user.lockedUntil().isAfter(LocalDateTime.now())) {
            log.warn("Login rejected: user '{}' is locked until {}", request.username(), user.lockedUntil());
            throw new AccountLockedException("Account is temporarily locked. Please try again later.");
        }

        if (!passwordEncoder.matches(request.password(), user.passwordHash())) {
            log.warn("Login failed: password mismatch for user '{}'", request.username());
            recordLoginAttempt(user.userId(), false);
            throw new BadCredentialsException("Invalid username or password");
        }

        // Login succeeded
        recordLoginAttempt(user.userId(), true);

        UserSummaryDto userSummary = getUserSummary(user.userId());
        UserPrincipal principal = new UserPrincipal(
                user.userId(),
                user.username(),
                "",
                userSummary != null ? userSummary.fullName() : user.username(),
                userSummary != null ? userSummary.email() : "",
                user.roleName(),
                true,
                true
        );

        String token = jwtTokenProvider.generateToken(principal);
        return AuthResponse.of(token, userSummary);
    }

    public UserSummaryDto getMe() {
        Integer currentUserId = SecurityUtils.getRequiredCurrentUserId();
        UserSummaryDto summary = getUserSummary(currentUserId);
        if (summary == null) {
            throw new BadCredentialsException("User not found");
        }
        return summary;
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        Integer currentUserId = SecurityUtils.getRequiredCurrentUserId();

        // Team Rule 5: Set MySQL session user so audit/triggers know who made changes
        dbSessionContext.setAppUser(currentUserId);

        String currentHash = jdbcTemplate.queryForObject(
                "SELECT password_hash FROM app_user WHERE user_id = ?",
                String.class,
                currentUserId
        );

        if (currentHash == null || !passwordEncoder.matches(request.oldPassword(), currentHash)) {
            throw new BadCredentialsException("Current password does not match");
        }

        if (request.newPassword().length() < 8) {
            throw new IllegalArgumentException("New password must be at least 8 characters long");
        }

        String newHash = passwordEncoder.encode(request.newPassword());
        jdbcTemplate.update(
                "UPDATE app_user SET password_hash = ? WHERE user_id = ?",
                newHash,
                currentUserId
        );
        log.info("Password changed successfully for user ID {}", currentUserId);
    }

    private LoginUserRecord loadLoginUser(String username) {
        String sql = "CALL sp_get_login_user(?)";
        try {
            return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> {
                Timestamp lockedTs = rs.getTimestamp("locked_until");
                LocalDateTime lockedUntil = lockedTs != null ? lockedTs.toLocalDateTime() : null;

                return new LoginUserRecord(
                        rs.getInt("user_id"),
                        rs.getString("username"),
                        rs.getString("password_hash"),
                        rs.getString("role_name"),
                        rs.getBoolean("is_active"),
                        rs.getInt("failed_attempts"),
                        lockedUntil
                );
            }, username);
        } catch (EmptyResultDataAccessException ex) {
            return null;
        }
    }

    private void recordLoginAttempt(Integer userId, boolean success) {
        try {
            jdbcTemplate.update("CALL sp_record_login(?, ?)", userId, success);
        } catch (Exception ex) {
            log.error("Failed to execute sp_record_login for user ID {}", userId, ex);
        }
    }

    private UserSummaryDto getUserSummary(Integer userId) {
        String sql = "SELECT id, username, full_name, email, phone, role_name, is_active, created_at, last_login_at " +
                     "FROM v_user_public WHERE id = ?";
        try {
            return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> {
                Timestamp createdTs = rs.getTimestamp("created_at");
                Timestamp loginTs = rs.getTimestamp("last_login_at");

                return new UserSummaryDto(
                        rs.getInt("id"),
                        rs.getString("username"),
                        rs.getString("full_name"),
                        rs.getString("email"),
                        rs.getString("phone"),
                        rs.getString("role_name"),
                        rs.getBoolean("is_active"),
                        createdTs != null ? createdTs.toLocalDateTime() : null,
                        loginTs != null ? loginTs.toLocalDateTime() : null
                );
            }, userId);
        } catch (EmptyResultDataAccessException ex) {
            return null;
        }
    }
}
