package com.backend.backend.dto.session;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class SessionCreateDTO {
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Double latitude;
    private Double longitude;
    private Double radiusInMeters;
    private Long courseId;
    private Long professorId;
}
