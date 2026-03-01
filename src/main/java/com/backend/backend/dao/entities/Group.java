package com.backend.backend.dao.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnore;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "groups", indexes = {@Index(columnList = "filiere" )})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Group {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    // Level / year (1, 2, ...)
    @Column(nullable = false)
    private String level;

    // Section name / letter (A, B, C...)
    private String section;

    // Filiere like IAGI, GSI, ...
    private String filiere;

    // Number of students currently enrolled
    @Column(nullable = false)
    private Integer totalStudents = 0;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "group", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<User> students = new ArrayList<>();

    @OneToMany(mappedBy = "group", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<Session> sessions = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (totalStudents == null) {
            totalStudents = 0;
        }
    }

    // Business logic helpers
    public synchronized void enrollStudent() {
        if (totalStudents == null) totalStudents = 0;
        totalStudents = totalStudents + 1;
    }

    public synchronized void unenrollStudent() {
        if (totalStudents == null || totalStudents <= 0) return;
        totalStudents = totalStudents - 1;
    }
}
