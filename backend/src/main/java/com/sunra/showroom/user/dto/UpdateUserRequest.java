package com.sunra.showroom.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
        @NotBlank(message = "Full name is required")
        @Size(max = 100, message = "Full name must not exceed 100 characters")
        String fullName,

        @NotBlank(message = "Email is required")
        @Email(message = "Valid email is required")
        @Size(max = 100, message = "Email must not exceed 100 characters")
        String email,

        @Size(max = 15, message = "Phone must not exceed 15 characters")
        String phone
) {}
