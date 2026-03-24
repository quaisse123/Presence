package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Attendance;
import com.backend.backend.dao.entities.AttendanceStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Long> {

	@Query("""
			SELECT a FROM Attendance a
			JOIN a.session s
			JOIN s.course c
			WHERE a.student.id = :studentId
			AND (:startDate IS NULL OR s.startTime >= :startDate)
			AND (:endDate IS NULL OR s.startTime <= :endDate)
			AND (:status IS NULL OR a.status = :status)
			AND (
				:search IS NULL
				OR LOWER(c.title) LIKE LOWER(CONCAT('%', :search, '%'))
				OR LOWER(c.code) LIKE LOWER(CONCAT('%', :search, '%'))
				OR LOWER(COALESCE(s.salle, '')) LIKE LOWER(CONCAT('%', :search, '%'))
			)
			ORDER BY s.startTime DESC
			""")
	List<Attendance> findStudentAttendancesWithFilters(
			@Param("studentId") Long studentId,
			@Param("startDate") LocalDateTime startDate,
			@Param("endDate") LocalDateTime endDate,
			@Param("status") AttendanceStatus status,
			@Param("search") String search
	);

	@Query("""
			SELECT COUNT(DISTINCT a.session.id) FROM Attendance a
			JOIN a.session s
			WHERE a.student.id = :studentId
			AND s.endTime <= :now
			AND (:startDate IS NULL OR s.startTime >= :startDate)
			AND (:endDate IS NULL OR s.startTime <= :endDate)
			AND a.status IN :attendedStatuses
			""")
	long countAttendedSessionsByStudentWithPeriod(
			@Param("studentId") Long studentId,
			@Param("now") LocalDateTime now,
			@Param("startDate") LocalDateTime startDate,
			@Param("endDate") LocalDateTime endDate,
			@Param("attendedStatuses") List<AttendanceStatus> attendedStatuses
	);
}
