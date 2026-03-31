package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    // First name collected during activation step 2.
    private String firstName;

    // Last name collected during activation step 2.
    private String lastName;

    @Column(nullable = false)
    private String password;

    // Student identifier provided on activation form.
    @Column(name = "code_apogee", unique = true)
    private String codeApogee;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    // Account activation status (default is INACTIVE until activation completes).
    @Enumerated(EnumType.STRING)
    @Column(name = "account_status")
    private Status status = Status.INACTIVE;

    private String biometricToken;

    @ManyToOne
    @JoinColumn(name = "group_id")
    private Group group;

    @OneToMany(mappedBy = "professor", cascade = CascadeType.ALL)
    private List<Session> sessions = new ArrayList<>();

    @OneToMany(mappedBy = "student", cascade = CascadeType.ALL)
    private List<Attendance> attendances = new ArrayList<>();

    @PrePersist
    protected void ensureDefaults() {
        if (status == null) {
            status = Status.INACTIVE;
        }
    }
}
