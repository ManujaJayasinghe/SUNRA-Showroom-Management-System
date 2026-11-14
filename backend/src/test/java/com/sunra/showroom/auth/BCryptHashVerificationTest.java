package com.sunra.showroom.auth;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertTrue;

class BCryptHashVerificationTest {

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder(10);

    @Test
    @DisplayName("BCrypt matches V1_1 seed hashes for demo accounts")
    void verifyV1Hashes() {
        assertTrue(passwordEncoder.matches("Admin@123", "$2a$10$nt1p1HY1jz4UrnLaEK4bR..ozKX4NFTWbKwfOE13pMuMl/5BRKP6a"),
                "Admin password should match V1_1 hash");
        assertTrue(passwordEncoder.matches("Sales@123", "$2a$10$q7oadz2zKEIYhr07xfF3tuPaGDdhg2xvGHJflfgPiBH6/fCHTQHsW"),
                "Sales password should match V1_1 hash");
        assertTrue(passwordEncoder.matches("Stock@123", "$2a$10$ylmV5T0z9jIDW6zzeq00duLFu1ie5kT6fmPb1s3D1yMf8Nn8dy1aa"),
                "Stock password should match V1_1 hash");
    }

    @Test
    @DisplayName("BCrypt matches V2_2 migration hashes for demo accounts")
    void verifyV2Hashes() {
        assertTrue(passwordEncoder.matches("Admin@123", "$2a$10$BLXb19x8jqR5G3cd6JJAA.JWzRyFASow8Bhfc4R3N45zBcNyJoom2"),
                "Admin password should match V2_2 hash");
        assertTrue(passwordEncoder.matches("Sales@123", "$2a$10$hZ3OpORaeiUYWCm/gVHmZeMFuY8i/UfdCrUbaNKPAhkfi/TdqNrFS"),
                "Sales password should match V2_2 hash");
        assertTrue(passwordEncoder.matches("Stock@123", "$2a$10$n/pydScyHLMrh7qMQTz/VOR9BLAm.JZyrxgUtkWFt8dPRSY.i6HGW"),
                "Stock password should match V2_2 hash");
    }
}
