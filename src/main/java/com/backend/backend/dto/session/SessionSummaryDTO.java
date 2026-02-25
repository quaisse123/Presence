package com.backend.backend.dto.session;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class SessionSummaryDTO {
    private Long id;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Long courseId;
}
