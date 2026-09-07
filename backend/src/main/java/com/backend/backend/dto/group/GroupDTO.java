package com.backend.backend.dto.group;

import lombok.Data;

/**
 * Lightweight group DTO used to populate the professor's
 * "create session" form (group picker).
 */
@Data
public class GroupDTO {
    private Long id;
    private String level;
    private String section;
    private String filiere;
    private Integer totalStudents;
}
