package com.backend.backend.dto.attendance;

import com.backend.backend.dao.entities.AttendanceStatus;
import lombok.Data;
import java.time.LocalDateTime;

@Data
public class AttendanceDTO {
    private Long id;
    private LocalDateTime scanTime;
    private AttendanceStatus status;
    private Boolean isOfflineSync;
    private String deviceId;
    private Double scanLatitude;
    private Double scanLongitude;
    private Long studentId;
    private Long sessionId;
}
