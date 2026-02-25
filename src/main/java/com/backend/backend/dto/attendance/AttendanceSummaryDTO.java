package com.backend.backend.dto.attendance;

import com.backend.backend.dao.entities.AttendanceStatus;
import lombok.Data;
import java.time.LocalDateTime;

@Data
public class AttendanceSummaryDTO {
    private Long id;
    private LocalDateTime scanTime;
    private AttendanceStatus status;
    private Long studentId;
    private Long sessionId;
}
