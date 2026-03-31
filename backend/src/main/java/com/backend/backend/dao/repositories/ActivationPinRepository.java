package com.backend.backend.dao.repositories;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.backend.backend.dao.entities.ActivationPin;

@Repository
public interface ActivationPinRepository extends JpaRepository<ActivationPin, Long> {

    Optional<ActivationPin> findByEmail(String email);

    void deleteByEmail(String email);
}
