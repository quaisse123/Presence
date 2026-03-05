package com.backend.backend.dto.session;

import lombok.Data;

@Data
public class SessionGroupDTO {
    private Long id;
    private String level;
    private String section;
    private String filiere;
    private Integer totalStudents;
}
