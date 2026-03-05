package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Session;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SessionRepository extends JpaRepository<Session, Long> {
    Page<Session> findAllByOrderByStartTimeDesc(Pageable pageable); // ou Asc pour croissant
}
