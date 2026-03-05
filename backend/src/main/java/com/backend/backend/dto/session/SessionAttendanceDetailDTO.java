package com.backend.backend.dto.session;

import com.backend.backend.dao.entities.AttendanceStatus;
import lombok.Data;
import java.time.LocalDateTime;

@Data
public class SessionAttendanceDetailDTO {
    private Long id;
    private LocalDateTime scanTime;
    private String studentEmail;
    private AttendanceStatus status;
}
