package com.backend.backend.dto.session;

import com.backend.backend.dto.course.CourseSummaryDTO;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Full session details DTO – used by the professor's session details page.
 * GPS fields (latitude, longitude, radiusInMeters) are intentionally excluded
 * (backend-only verification).
 */
@Data
public class SessionDTO {

    // ── Session flat fields ───────────────────────────────────────────────
    private Long id;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String qrCodeToken;
    private String salle;
    private String description;

    // ── Nested – Course (title + code) ───────────────────────────────────
    private CourseSummaryDTO course;

    // ── Nested – Group ───────────────────────────────────────────────────
    private SessionGroupDTO group;

    // ── Nested – Attendances ─────────────────────────────────────────────
    private List<SessionAttendanceDetailDTO> attendances;

    // ── Computed status ───────────────────────────────────────────────────
    public enum SessionStatus { UPCOMING, ACTIVE, COMPLETED }

    @JsonProperty("sessionStatus")
    public SessionStatus getSessionStatus() {
        if (startTime == null || endTime == null) return SessionStatus.UPCOMING;
        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(startTime)) return SessionStatus.UPCOMING;
        else if (now.isAfter(endTime)) return SessionStatus.COMPLETED;
        else return SessionStatus.ACTIVE;
    }
}
