package com.backend.backend.dto.user;

import com.backend.backend.dao.entities.Role;
import lombok.Data;

@Data
public class UserSummaryDTO {
    private Long id;
    private String email;
    private Role role;
}
