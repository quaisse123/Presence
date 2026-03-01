package com.backend.backend.dto.session;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class SessionDTO {
    private Long id;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String qrCodeToken;
    private String salle;
    private Double latitude;
    private Double longitude;
    private Double radiusInMeters;
    private Long courseId;
    private Long professorId;
}
