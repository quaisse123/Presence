package com.backend.backend.dto.session;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class SessionResponseDTO {
    private Long id;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String qrCodeToken;
    private Double latitude;
    private Double longitude;
    private Double radiusInMeters;
    private Long courseId;
    private Long professorId;
}
