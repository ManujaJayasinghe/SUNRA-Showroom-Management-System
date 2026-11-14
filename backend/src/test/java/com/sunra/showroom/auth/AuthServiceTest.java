package com.sunra.showroom.auth;

import com.sunra.showroom.auth.dto.AuthResponse;
import com.sunra.showroom.auth.dto.LoginRequest;
import com.sunra.showroom.auth.exception.AccountDeactivatedException;
import com.sunra.showroom.auth.exception.AccountLockedException;
import com.sunra.showroom.auth.security.JwtTokenProvider;
import com.sunra.showroom.auth.security.UserPrincipal;
import com.sunra.showroom.auth.service.AuthService;
import com.sunra.showroom.common.db.DbSessionContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @Mock
    private DbSessionContext dbSessionContext;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder(10);
    private AuthService authService;

    private final String hashedPwd = "$2a$10$BLXb19x8jqR5G3cd6JJAA.JWzRyFASow8Bhfc4R3N45zBcNyJoom2"; // Admin@123

    @BeforeEach
    void setUp() {
        authService = new AuthService(jdbcTemplate, passwordEncoder, jwtTokenProvider, dbSessionContext);
    }

    @Test
    @DisplayName("Successful login calls sp_record_login(userId, true) and generates JWT")
    @SuppressWarnings("unchecked")
    void login_success() throws Exception {
        // Mock sp_get_login_user
        when(jdbcTemplate.queryForObject(eq("CALL sp_get_login_user(?)"), any(RowMapper.class), eq("admin")))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getInt("user_id")).thenReturn(1);
                    when(rs.getString("username")).thenReturn("admin");
                    when(rs.getString("password_hash")).thenReturn(hashedPwd);
                    when(rs.getString("role_name")).thenReturn("ADMIN");
                    when(rs.getBoolean("is_active")).thenReturn(true);
                    when(rs.getInt("failed_attempts")).thenReturn(0);
                    when(rs.getTimestamp("locked_until")).thenReturn(null);
                    return mapper.mapRow(rs, 1);
                });

        // Mock v_user_public query
        when(jdbcTemplate.queryForObject(startsWith("SELECT id, username"), any(RowMapper.class), eq(1)))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getInt("id")).thenReturn(1);
                    when(rs.getString("username")).thenReturn("admin");
                    when(rs.getString("full_name")).thenReturn("System Administrator");
                    when(rs.getString("email")).thenReturn("admin@sunra.local");
                    when(rs.getString("phone")).thenReturn("0771234567");
                    when(rs.getString("role_name")).thenReturn("ADMIN");
                    when(rs.getBoolean("is_active")).thenReturn(true);
                    when(rs.getTimestamp("created_at")).thenReturn(Timestamp.valueOf(LocalDateTime.now()));
                    when(rs.getTimestamp("last_login_at")).thenReturn(null);
                    return mapper.mapRow(rs, 1);
                });

        when(jwtTokenProvider.generateToken(any(UserPrincipal.class))).thenReturn("valid-jwt-token");

        LoginRequest request = new LoginRequest("admin", "Admin@123");
        AuthResponse response = authService.login(request);

        assertNotNull(response);
        assertEquals("valid-jwt-token", response.token());
        assertEquals("admin", response.user().username());
        assertEquals("ADMIN", response.user().role());

        // Verify successful attempt recorded
        verify(jdbcTemplate, times(1)).update("CALL sp_record_login(?, ?)", 1, true);
    }

    @Test
    @DisplayName("Wrong password records failure and throws 401 with generic message")
    @SuppressWarnings("unchecked")
    void login_wrongPassword() throws Exception {
        when(jdbcTemplate.queryForObject(eq("CALL sp_get_login_user(?)"), any(RowMapper.class), eq("admin")))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getInt("user_id")).thenReturn(1);
                    when(rs.getString("username")).thenReturn("admin");
                    when(rs.getString("password_hash")).thenReturn(hashedPwd);
                    when(rs.getString("role_name")).thenReturn("ADMIN");
                    when(rs.getBoolean("is_active")).thenReturn(true);
                    when(rs.getInt("failed_attempts")).thenReturn(2);
                    when(rs.getTimestamp("locked_until")).thenReturn(null);
                    return mapper.mapRow(rs, 1);
                });

        LoginRequest request = new LoginRequest("admin", "WrongPass123");
        BadCredentialsException ex = assertThrows(BadCredentialsException.class, () -> authService.login(request));

        assertEquals("Invalid username or password", ex.getMessage());

        // Verify failed attempt recorded via sp_record_login
        verify(jdbcTemplate, times(1)).update("CALL sp_record_login(?, ?)", 1, false);
    }

    @Test
    @DisplayName("Inactive user is rejected with AccountDeactivatedException")
    @SuppressWarnings("unchecked")
    void login_inactiveUser() throws Exception {
        when(jdbcTemplate.queryForObject(eq("CALL sp_get_login_user(?)"), any(RowMapper.class), eq("sales1")))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getInt("user_id")).thenReturn(2);
                    when(rs.getString("username")).thenReturn("sales1");
                    when(rs.getString("password_hash")).thenReturn(hashedPwd);
                    when(rs.getString("role_name")).thenReturn("SALES");
                    when(rs.getBoolean("is_active")).thenReturn(false);
                    return mapper.mapRow(rs, 1);
                });

        LoginRequest request = new LoginRequest("sales1", "Admin@123");
        AccountDeactivatedException ex = assertThrows(AccountDeactivatedException.class, () -> authService.login(request));

        assertTrue(ex.getMessage().contains("deactivated"));
        // Did not record login because user is deactivated
        verify(jdbcTemplate, never()).update(eq("CALL sp_record_login(?, ?)"), any(), any());
    }

    @Test
    @DisplayName("Locked user is rejected with AccountLockedException")
    @SuppressWarnings("unchecked")
    void login_lockedUser() throws Exception {
        LocalDateTime futureLock = LocalDateTime.now().plusMinutes(10);
        when(jdbcTemplate.queryForObject(eq("CALL sp_get_login_user(?)"), any(RowMapper.class), eq("sales1")))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getInt("user_id")).thenReturn(2);
                    when(rs.getString("username")).thenReturn("sales1");
                    when(rs.getString("password_hash")).thenReturn(hashedPwd);
                    when(rs.getString("role_name")).thenReturn("SALES");
                    when(rs.getBoolean("is_active")).thenReturn(true);
                    when(rs.getInt("failed_attempts")).thenReturn(5);
                    when(rs.getTimestamp("locked_until")).thenReturn(Timestamp.valueOf(futureLock));
                    return mapper.mapRow(rs, 1);
                });

        LoginRequest request = new LoginRequest("sales1", "Admin@123");
        AccountLockedException ex = assertThrows(AccountLockedException.class, () -> authService.login(request));

        assertTrue(ex.getMessage().contains("locked"));
        verify(jdbcTemplate, never()).update(eq("CALL sp_record_login(?, ?)"), any(), any());
    }

    @Test
    @DisplayName("Multiple failed attempts trigger failure recording on each attempt")
    @SuppressWarnings("unchecked")
    void lockout_consecutiveFailedAttempts() throws Exception {
        when(jdbcTemplate.queryForObject(eq("CALL sp_get_login_user(?)"), any(RowMapper.class), eq("admin")))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getInt("user_id")).thenReturn(1);
                    when(rs.getString("username")).thenReturn("admin");
                    when(rs.getString("password_hash")).thenReturn(hashedPwd);
                    when(rs.getString("role_name")).thenReturn("ADMIN");
                    when(rs.getBoolean("is_active")).thenReturn(true);
                    when(rs.getInt("failed_attempts")).thenReturn(4);
                    when(rs.getTimestamp("locked_until")).thenReturn(null);
                    return mapper.mapRow(rs, 1);
                });

        LoginRequest request = new LoginRequest("admin", "BadPassword");

        assertThrows(BadCredentialsException.class, () -> authService.login(request));
        verify(jdbcTemplate, times(1)).update("CALL sp_record_login(?, ?)", 1, false);
    }
}
