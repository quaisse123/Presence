package com.backend.backend.dto.session;

import lombok.Data;

import java.util.List;

@Data
public class StudentSessionHistoryResponseDTO {
    private Integer totalSessions;
    private Integer attendedSessions;
    private Integer missedSessions;
    private List<StudentSessionHistoryItemDTO> items;
}
