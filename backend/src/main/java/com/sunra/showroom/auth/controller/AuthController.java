package com.sunra.showroom.auth.controller;

import com.sunra.showroom.auth.dto.AuthResponse;
import com.sunra.showroom.auth.dto.ChangePasswordRequest;
import com.sunra.showroom.auth.dto.LoginRequest;
import com.sunra.showroom.auth.dto.UserSummaryDto;
import com.sunra.showroom.auth.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @GetMapping("/me")
    public ResponseEntity<UserSummaryDto> getMe() {
        return ResponseEntity.ok(authService.getMe());
    }

    @PostMapping("/change-password")
    public ResponseEntity<Map<String, String>> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(request);
        return ResponseEntity.ok(Map.of("message", "Password changed successfully"));
    }
}
