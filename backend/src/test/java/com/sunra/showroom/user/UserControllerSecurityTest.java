package com.sunra.showroom.user;

import com.sunra.showroom.auth.security.*;
import com.sunra.showroom.common.exception.GlobalExceptionHandler;
import com.sunra.showroom.user.controller.UserController;
import com.sunra.showroom.user.dto.UserDto;
import com.sunra.showroom.user.service.UserService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, RestAuthenticationEntryPoint.class, RestAccessDeniedHandler.class, GlobalExceptionHandler.class})
class UserControllerSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    @DisplayName("Admin token can call /api/users (HTTP 200) and response contains no password hash")
    @WithMockUser(username = "admin", roles = {"ADMIN"})
    void listUsers_asAdmin_shouldReturnOkAndNoHash() throws Exception {
        UserDto user1 = new UserDto(1, "admin", "Administrator", "admin@sunra.local", "0771234567", "ADMIN", true, LocalDateTime.now(), null);
        UserDto user2 = new UserDto(2, "sales1", "Sales Assistant", "sales1@sunra.local", "0772345678", "SALES", true, LocalDateTime.now(), null);
        when(userService.getUsers(any(), any())).thenReturn(List.of(user1, user2));

        mockMvc.perform(get("/api/users").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].username").value("admin"))
                .andExpect(jsonPath("$[0].role").value("ADMIN"))
                .andExpect(jsonPath("$[0].password").doesNotExist())
                .andExpect(jsonPath("$[0].passwordHash").doesNotExist())
                .andExpect(jsonPath("$[0].password_hash").doesNotExist())
                .andExpect(jsonPath("$[1].username").value("sales1"))
                .andExpect(jsonPath("$[1].password").doesNotExist())
                .andExpect(jsonPath("$[1].passwordHash").doesNotExist())
                .andExpect(content().string(not(containsString("password_hash"))))
                .andExpect(content().string(not(containsString("$2a$10$"))));
    }

    @Test
    @DisplayName("Sales token calling admin-only /api/users returns HTTP 403 Forbidden")
    @WithMockUser(username = "sales1", roles = {"SALES"})
    void listUsers_asSales_shouldReturnForbidden() throws Exception {
        mockMvc.perform(get("/api/users").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403))
                .andExpect(jsonPath("$.error").value("Access denied"))
                .andExpect(jsonPath("$.message").value("You do not have permission to access this resource"));
    }

    @Test
    @DisplayName("Stock token calling admin-only /api/users returns HTTP 403 Forbidden")
    @WithMockUser(username = "stock1", roles = {"STOCK"})
    void listUsers_asStock_shouldReturnForbidden() throws Exception {
        mockMvc.perform(get("/api/users").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403))
                .andExpect(jsonPath("$.error").value("Access denied"))
                .andExpect(jsonPath("$.message").value("You do not have permission to access this resource"));
    }

    @Test
    @DisplayName("Unauthenticated request to /api/users returns HTTP 401 Unauthorized")
    void listUsers_unauthenticated_shouldReturnUnauthorized() throws Exception {
        mockMvc.perform(get("/api/users").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.error").value("Unauthorized"));
    }
}
