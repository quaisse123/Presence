package com.backend.backend.dto.session;

import com.backend.backend.dao.entities.AttendanceStatus;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class StudentSessionHistoryItemDTO {
    private Long sessionId;
    private String courseTitle;
    private String courseCode;
    private String professorName;
    private String salle;
    private LocalDateTime sessionStartTime;
    private LocalDateTime sessionEndTime;

    private AttendanceStatus status;
    private LocalDateTime scanTime;
}
