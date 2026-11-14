package com.sunra.showroom.auth.dto;

import java.time.LocalDateTime;

public record UserSummaryDto(
        Integer id,
        String username,
        String fullName,
        String email,
        String phone,
        String role,
        Boolean isActive,
        LocalDateTime createdAt,
        LocalDateTime lastLoginAt
) {}
