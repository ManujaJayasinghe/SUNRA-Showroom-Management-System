package com.sunra.showroom.user.dto;

import java.time.LocalDateTime;

public record UserDto(
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
