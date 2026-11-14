package com.sunra.showroom.user.dto;

import jakarta.validation.constraints.NotNull;

public record UpdateStatusRequest(
        @NotNull(message = "isActive flag is required")
        Boolean isActive
) {}
