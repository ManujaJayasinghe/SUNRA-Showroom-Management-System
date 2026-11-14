package com.sunra.showroom.user.service;

import com.sunra.showroom.auth.exception.DuplicateUsernameException;
import com.sunra.showroom.auth.security.SecurityUtils;
import com.sunra.showroom.common.db.DbSessionContext;
import com.sunra.showroom.user.dto.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder passwordEncoder;
    private final DbSessionContext dbSessionContext;

    public List<UserDto> getUsers(String search, String role) {
        StringBuilder sql = new StringBuilder(
                "SELECT id, username, full_name, email, phone, role_name, is_active, created_at, last_login_at " +
                "FROM v_user_public WHERE 1=1"
        );
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            String searchPattern = "%" + search.trim().toLowerCase() + "%";
            sql.append(" AND (LOWER(username) LIKE ? OR LOWER(full_name) LIKE ? OR LOWER(email) LIKE ?)");
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }

        if (role != null && !role.trim().isEmpty()) {
            sql.append(" AND role_name = ?");
            params.add(role.trim().toUpperCase());
        }

        sql.append(" ORDER BY id ASC");

        return jdbcTemplate.query(sql.toString(), (rs, rowNum) -> mapUserDto(rs), params.toArray());
    }

    public UserDto getUserById(Integer id) {
        String sql = "SELECT id, username, full_name, email, phone, role_name, is_active, created_at, last_login_at " +
                     "FROM v_user_public WHERE id = ?";
        try {
            return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> mapUserDto(rs), id);
        } catch (EmptyResultDataAccessException ex) {
            throw new IllegalArgumentException("User not found with ID: " + id);
        }
    }

    @Transactional
    public UserDto createUser(CreateUserRequest request) {
        Integer currentUserId = SecurityUtils.getRequiredCurrentUserId();

        // 1. Check duplicate username
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM app_user WHERE username = ?",
                Integer.class,
                request.username()
        );
        if (count != null && count > 0) {
            throw new DuplicateUsernameException("Username '" + request.username() + "' is already in use");
        }

        // 2. Lookup role ID
        Integer roleId = lookupRoleId(request.role());

        // 3. Hash initial password
        String passwordHash = passwordEncoder.encode(request.password());

        // 4. Team Rule 5: Set MySQL session user
        dbSessionContext.setAppUser(currentUserId);

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    "INSERT INTO app_user (username, role_id, password_hash, full_name, email, phone, is_active) " +
                    "VALUES (?, ?, ?, ?, ?, ?, TRUE)",
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setString(1, request.username().trim());
            ps.setInt(2, roleId);
            ps.setString(3, passwordHash);
            ps.setString(4, request.fullName().trim());
            ps.setString(5, request.email().trim());
            ps.setString(6, request.phone() != null ? request.phone().trim() : null);
            return ps;
        }, keyHolder);

        Number key = keyHolder.getKey();
        if (key == null) {
            throw new IllegalStateException("Failed to insert user, no ID generated");
        }

        log.info("User '{}' (ID: {}) created by admin ID {}", request.username(), key.intValue(), currentUserId);
        return getUserById(key.intValue());
    }

    @Transactional
    public UserDto updateUser(Integer id, UpdateUserRequest request) {
        Integer currentUserId = SecurityUtils.getRequiredCurrentUserId();
        ensureUserExists(id);

        dbSessionContext.setAppUser(currentUserId);

        jdbcTemplate.update(
                "UPDATE app_user SET full_name = ?, email = ?, phone = ? WHERE user_id = ?",
                request.fullName().trim(),
                request.email().trim(),
                request.phone() != null ? request.phone().trim() : null,
                id
        );

        log.info("User ID {} updated by admin ID {}", id, currentUserId);
        return getUserById(id);
    }

    @Transactional
    public UserDto updateRole(Integer id, UpdateRoleRequest request) {
        Integer currentUserId = SecurityUtils.getRequiredCurrentUserId();
        ensureUserExists(id);

        // Security rule: admin cannot demote their own account
        if (currentUserId.equals(id) && !"ADMIN".equalsIgnoreCase(request.role().trim())) {
            throw new IllegalStateException("Administrators cannot change or demote their own role");
        }

        Integer roleId = lookupRoleId(request.role());

        dbSessionContext.setAppUser(currentUserId);

        jdbcTemplate.update(
                "UPDATE app_user SET role_id = ? WHERE user_id = ?",
                roleId,
                id
        );

        log.info("Role for user ID {} changed to {} by admin ID {}", id, request.role(), currentUserId);
        return getUserById(id);
    }

    @Transactional
    public UserDto updateStatus(Integer id, UpdateStatusRequest request) {
        Integer currentUserId = SecurityUtils.getRequiredCurrentUserId();
        ensureUserExists(id);

        // Security rule: admin cannot deactivate their own account
        if (currentUserId.equals(id) && Boolean.FALSE.equals(request.isActive())) {
            throw new IllegalStateException("Administrators cannot deactivate their own account");
        }

        dbSessionContext.setAppUser(currentUserId);

        jdbcTemplate.update(
                "UPDATE app_user SET is_active = ? WHERE user_id = ?",
                request.isActive(),
                id
        );

        log.info("Active status for user ID {} set to {} by admin ID {}", id, request.isActive(), currentUserId);
        return getUserById(id);
    }

    @Transactional
    public void resetPassword(Integer id, ResetPasswordRequest request) {
        Integer currentUserId = SecurityUtils.getRequiredCurrentUserId();
        ensureUserExists(id);

        if (request.newPassword().length() < 8) {
            throw new IllegalArgumentException("Password must be at least 8 characters long");
        }

        String passwordHash = passwordEncoder.encode(request.newPassword());

        dbSessionContext.setAppUser(currentUserId);

        jdbcTemplate.update(
                "UPDATE app_user SET password_hash = ?, failed_attempts = 0, locked_until = NULL WHERE user_id = ?",
                passwordHash,
                id
        );

        log.info("Password for user ID {} reset by admin ID {}", id, currentUserId);
    }

    private Integer lookupRoleId(String roleName) {
        try {
            return jdbcTemplate.queryForObject(
                    "SELECT role_id FROM role WHERE role_name = ?",
                    Integer.class,
                    roleName.trim().toUpperCase()
            );
        } catch (EmptyResultDataAccessException ex) {
            throw new IllegalArgumentException("Invalid role name: " + roleName);
        }
    }

    private void ensureUserExists(Integer id) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM app_user WHERE user_id = ?",
                Integer.class,
                id
        );
        if (count == null || count == 0) {
            throw new IllegalArgumentException("User not found with ID: " + id);
        }
    }

    private UserDto mapUserDto(java.sql.ResultSet rs) throws java.sql.SQLException {
        Timestamp createdTs = rs.getTimestamp("created_at");
        Timestamp loginTs = rs.getTimestamp("last_login_at");

        return new UserDto(
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
    }
}
