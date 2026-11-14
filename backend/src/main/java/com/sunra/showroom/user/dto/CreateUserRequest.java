package com.sunra.showroom.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateUserRequest(
        @NotBlank(message = "Username is required")
        @Size(min = 4, max = 50, message = "Username must be between 4 and 50 characters")
        String username,

        @NotBlank(message = "Full name is required")
        @Size(max = 100, message = "Full name must not exceed 100 characters")
        String fullName,

        @NotBlank(message = "Email is required")
        @Email(message = "Valid email is required")
        @Size(max = 100, message = "Email must not exceed 100 characters")
        String email,

        @Size(max = 15, message = "Phone must not exceed 15 characters")
        String phone,

        @NotBlank(message = "Role is required")
        String role,

        @NotBlank(message = "Initial password is required")
        @Size(min = 8, message = "Password must be at least 8 characters long")
        String password
) {}
