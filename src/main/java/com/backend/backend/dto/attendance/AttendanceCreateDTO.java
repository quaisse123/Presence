package com.backend.backend.dto.attendance;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class AttendanceCreateDTO {
    private LocalDateTime scanTime;
    private Boolean isOfflineSync;
    private String deviceId;
    private Double scanLatitude;
    private Double scanLongitude;
    private Long studentId;
    private Long sessionId;
}
