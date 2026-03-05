package com.backend.backend.dto.course;

import lombok.Data;
import java.util.List;

@Data
public class CourseDTO {
    private Long id;
    private String title;
    private String code;

    private List<CourseSessionDTO> sessions;
}
