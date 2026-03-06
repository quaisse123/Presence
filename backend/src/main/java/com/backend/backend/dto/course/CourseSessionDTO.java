package com.backend.backend.dto.course;

import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class CourseSessionDTO {
    private Long id;
    private LocalDate date;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String salle;
}
