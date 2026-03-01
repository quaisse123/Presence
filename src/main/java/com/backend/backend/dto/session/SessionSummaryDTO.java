package com.backend.backend.dto.session;

import lombok.Data;
import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonProperty;

@Data
public class SessionSummaryDTO {
    private Long id;

    private String courseTitle;
    private String courseCode;

    private String salle;

    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Long courseId;

    private int attendance;
    private int totalStudents;

    private String description;



    // enum status
    public enum SessionStatus {
        UPCOMING,
        ACTIVE,
        COMPLETED
    }

    @JsonProperty("sessionStatus")
    public SessionStatus getSessionStatus() {
        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(startTime)) {
            return SessionStatus.UPCOMING;
        } else if (now.isAfter(endTime)) {
            return SessionStatus.COMPLETED;
        } else {    
            return SessionStatus.ACTIVE;
        }   
    }
}
