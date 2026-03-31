package com.backend.backend.service;

import com.backend.backend.dao.entities.Group;
import org.springframework.stereotype.Component;

@Component
public class ActivationMembershipHelper {

    // TODO: replace this stub with real enrollment verification source.
    public boolean belongsToSelectedGroup(String email, String codeApogee, Group group) {
        return true;
    }
}