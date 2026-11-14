package com.sunra.showroom.auth.service;

import java.time.LocalDateTime;

public record LoginUserRecord(
        Integer userId,
        String username,
        String passwordHash,
        String roleName,
        boolean active,
        int failedAttempts,
        LocalDateTime lockedUntil
) {}
