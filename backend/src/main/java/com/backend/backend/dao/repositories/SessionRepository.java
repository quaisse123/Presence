package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Session;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SessionRepository extends JpaRepository<Session, Long> {
    Page<Session> findAllByOrderByStartTimeDesc(Pageable pageable); // ou Asc pour croissant

    Session getSessionByQrCodeToken(String qrCodeToken);

    @Query("""
            SELECT COUNT(s) FROM Session s
            WHERE s.group.id = :groupId
            AND s.startTime <= :now
            AND (:startDate IS NULL OR s.startTime >= :startDate)
            AND (:endDate IS NULL OR s.startTime <= :endDate)
            """)
    long countPastSessionsByGroupWithPeriod(
            @Param("groupId") Long groupId,
            @Param("now") LocalDateTime now,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    @Query("""
            SELECT s FROM Session s
            JOIN s.course c
            WHERE s.group.id = :groupId
            AND s.startTime <= :now
            AND (:startDate IS NULL OR s.startTime >= :startDate)
            AND (:endDate IS NULL OR s.startTime <= :endDate)
            AND (
                :search IS NULL
                OR LOWER(c.title) LIKE LOWER(CONCAT('%', :search, '%'))
                OR LOWER(c.code) LIKE LOWER(CONCAT('%', :search, '%'))
                OR LOWER(COALESCE(s.salle, '')) LIKE LOWER(CONCAT('%', :search, '%'))
            )
            ORDER BY s.startTime DESC
            """)
    List<Session> findStudentSessionsWithFilters(
            @Param("groupId") Long groupId,
            @Param("now") LocalDateTime now,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate,
            @Param("search") String search
    );
}
