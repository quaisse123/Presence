package com.backend.backend.dto.attendance;

import lombok.Data;

import java.util.List;

@Data
public class AttendanceMyResponseDTO {
    private Integer totalSessions;
    private Integer attendedSessions;
    private Integer missedSessions;
    private List<AttendanceSummaryDTO> items;
}
