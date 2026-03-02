package com.backend.backend.dto.user;

import com.backend.backend.dao.entities.Role;
import lombok.Data;

@Data
public class UserCreateDTO {
    private String email;
    private String password;
    private Role role;
    private String biometricToken;
}
