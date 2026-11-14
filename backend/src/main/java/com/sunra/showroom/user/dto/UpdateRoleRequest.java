package com.sunra.showroom.user.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateRoleRequest(
        @NotBlank(message = "Role is required")
        String role
) {}
