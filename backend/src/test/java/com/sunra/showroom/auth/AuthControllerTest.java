package com.sunra.showroom.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sunra.showroom.auth.controller.AuthController;
import com.sunra.showroom.auth.dto.AuthResponse;
import com.sunra.showroom.auth.dto.LoginRequest;
import com.sunra.showroom.auth.dto.UserSummaryDto;
import com.sunra.showroom.auth.exception.AccountDeactivatedException;
import com.sunra.showroom.auth.exception.AccountLockedException;
import com.sunra.showroom.auth.security.*;
import com.sunra.showroom.auth.service.AuthService;
import com.sunra.showroom.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AuthController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, RestAuthenticationEntryPoint.class, RestAccessDeniedHandler.class, GlobalExceptionHandler.class})
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    @DisplayName("Successful login returns JWT token and user summary without password hash (HTTP 200)")
    void login_success_shouldReturnToken() throws Exception {
        UserSummaryDto user = new UserSummaryDto(1, "admin", "Admin User", "admin@sunra.local", "0771234567", "ADMIN", true, LocalDateTime.now(), null);
        AuthResponse response = AuthResponse.of("mock-jwt-token-123", user);

        when(authService.login(any(LoginRequest.class))).thenReturn(response);

        LoginRequest request = new LoginRequest("admin", "Admin@123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("mock-jwt-token-123"))
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.user.username").value("admin"))
                .andExpect(jsonPath("$.user.role").value("ADMIN"))
                .andExpect(jsonPath("$.user.password").doesNotExist())
                .andExpect(jsonPath("$.user.passwordHash").doesNotExist())
                .andExpect(jsonPath("$.user.password_hash").doesNotExist())
                .andExpect(content().string(not(containsString("password_hash"))))
                .andExpect(content().string(not(containsString("$2a$10$"))));
    }

    @Test
    @DisplayName("Invalid credentials returns HTTP 401 with generic message")
    void login_badCredentials_shouldReturn401() throws Exception {
        when(authService.login(any(LoginRequest.class))).thenThrow(new BadCredentialsException("Invalid username or password"));

        LoginRequest request = new LoginRequest("admin", "WrongPassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.message").value("Invalid username or password"));
    }

    @Test
    @DisplayName("Deactivated user login returns HTTP 403")
    void login_deactivatedUser_shouldReturn403() throws Exception {
        when(authService.login(any(LoginRequest.class))).thenThrow(new AccountDeactivatedException("Account is deactivated. Please contact an administrator."));

        LoginRequest request = new LoginRequest("sales1", "Sales@123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403))
                .andExpect(jsonPath("$.message").value("Account is deactivated. Please contact an administrator."));
    }

    @Test
    @DisplayName("Locked user login returns HTTP 423")
    void login_lockedUser_shouldReturn423() throws Exception {
        when(authService.login(any(LoginRequest.class))).thenThrow(new AccountLockedException("Account is temporarily locked. Please try again later."));

        LoginRequest request = new LoginRequest("sales1", "Sales@123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().is(423))
                .andExpect(jsonPath("$.status").value(423))
                .andExpect(jsonPath("$.message").value("Account is temporarily locked. Please try again later."));
    }

    @Test
    @DisplayName("GET /api/auth/me without token returns HTTP 401")
    void getMe_withoutToken_shouldReturn401() throws Exception {
        mockMvc.perform(get("/api/auth/me").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.error").value("Unauthorized"));
    }

    @Test
    @DisplayName("GET /api/auth/me with authenticated user returns user summary without password hash")
    @WithMockUser(username = "admin", roles = {"ADMIN"})
    void getMe_authenticated_shouldReturnUserWithoutHash() throws Exception {
        UserSummaryDto user = new UserSummaryDto(1, "admin", "Admin User", "admin@sunra.local", "0771234567", "ADMIN", true, LocalDateTime.now(), null);
        when(authService.getMe()).thenReturn(user);

        mockMvc.perform(get("/api/auth/me").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.username").value("admin"))
                .andExpect(jsonPath("$.email").value("admin@sunra.local"))
                .andExpect(jsonPath("$.role").value("ADMIN"))
                .andExpect(jsonPath("$.password").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist())
                .andExpect(content().string(not(containsString("password_hash"))));
    }
}
