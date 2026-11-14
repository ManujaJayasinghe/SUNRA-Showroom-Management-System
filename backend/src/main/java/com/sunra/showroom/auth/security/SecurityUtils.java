package com.sunra.showroom.auth.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

public final class SecurityUtils {

    private SecurityUtils() {}

    public static Optional<UserPrincipal> getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserPrincipal principal) {
            return Optional.of(principal);
        }
        return Optional.empty();
    }

    public static Integer getCurrentUserId() {
        return getCurrentUser()
                .map(UserPrincipal::getUserId)
                .orElse(null);
    }

    public static Integer getRequiredCurrentUserId() {
        return getCurrentUser()
                .map(UserPrincipal::getUserId)
                .orElseThrow(() -> new IllegalStateException("No authenticated user found in SecurityContext"));
    }
}
