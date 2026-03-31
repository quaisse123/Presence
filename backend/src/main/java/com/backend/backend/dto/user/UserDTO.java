package com.backend.backend.dto.user;

import com.backend.backend.dao.entities.Role;
import com.backend.backend.dao.entities.Status;
import lombok.Data;

@Data
public class UserDTO {
    private Long id;
    private String email;
    private String firstName;
    private String lastName;
    private String password;
    private String codeApogee;
    private Role role;
    private Status status;
    private String biometricToken;
}
