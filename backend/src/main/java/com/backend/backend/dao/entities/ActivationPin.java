package com.backend.backend.dao.entities;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(
        name = "activation_pins",
        indexes = {
                @Index(name = "idx_activation_pin_email", columnList = "email", unique = true)
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ActivationPin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Institutional email used as unique key for activation state.
    @Column(nullable = false, unique = true)
    private String email;

    // Latest PIN generated for this email. Null once PIN is verified.
    @Column(length = 4)
    private String pin;

    // Creation timestamp used to enforce PIN expiration.
    @Column(name = "pin_created_at")
    private Instant pinCreatedAt;

    // Marker set after successful PIN verification.
    @Column(name = "pin_verified_at")
    private Instant pinVerifiedAt;
}
