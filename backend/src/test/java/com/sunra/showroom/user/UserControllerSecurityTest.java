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

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
    @DisplayName("Admin role can list users (HTTP 200)")
    @WithMockUser(username = "admin", roles = {"ADMIN"})
    void listUsers_asAdmin_shouldReturnOk() throws Exception {
        UserDto user = new UserDto(1, "admin", "Administrator", "admin@sunra.local", "0771234567", "ADMIN", true, LocalDateTime.now(), null);
        when(userService.getUsers(any(), any())).thenReturn(List.of(user));

        mockMvc.perform(get("/api/users").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].username").value("admin"))
                .andExpect(jsonPath("$[0].role").value("ADMIN"));
    }

    @Test
    @DisplayName("Sales role cannot list users (HTTP 403)")
    @WithMockUser(username = "sales1", roles = {"SALES"})
    void listUsers_asSales_shouldReturnForbidden() throws Exception {
        mockMvc.perform(get("/api/users").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403))
                .andExpect(jsonPath("$.error").value("Access denied"));
    }

    @Test
    @DisplayName("Stock role cannot list users (HTTP 403)")
    @WithMockUser(username = "stock1", roles = {"STOCK"})
    void listUsers_asStock_shouldReturnForbidden() throws Exception {
        mockMvc.perform(get("/api/users").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403))
                .andExpect(jsonPath("$.error").value("Access denied"));
    }

    @Test
    @DisplayName("Unauthenticated request to /api/users returns HTTP 401")
    void listUsers_unauthenticated_shouldReturnUnauthorized() throws Exception {
        mockMvc.perform(get("/api/users").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.error").value("Unauthorized"));
    }
}
