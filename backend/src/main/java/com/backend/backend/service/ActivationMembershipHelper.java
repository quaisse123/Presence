package com.backend.backend.service;

import com.backend.backend.dao.entities.Group;
import com.backend.backend.dao.entities.Role;
import com.backend.backend.dao.entities.User;
import com.backend.backend.dao.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class ActivationMembershipHelper {

    @Autowired
    private UserRepository userRepository;

    /**
     * Vérifie que l'étudiant (identifié par email / codeApogee) appartient bien
     * au groupe sélectionné.
     *
     * Approche simple et efficace : le code apogée est unique et lié à un groupe.
     * - Si un compte avec ce code apogée existe déjà et appartient à un AUTRE groupe
     *   que celui sélectionné → refus (le code apogée est déjà rattaché ailleurs).
     * - Si le compte existe déjà dans le groupe sélectionné → OK.
     * - Si le code apogée n'est utilisé par personne → OK (première activation).
     */
    public boolean belongsToSelectedGroup(String email, String codeApogee, Group group) {
        if (group == null) {
            return false;
        }

        // 1) Le compte email existe déjà et a déjà un groupe assigné ?
        User byEmail = userRepository.findByEmail(email);
        if (byEmail != null && byEmail.getGroup() != null) {
            return byEmail.getGroup().getId().equals(group.getId());
        }

        // 2) Le code apogée est-il déjà utilisé par un autre étudiant ?
        User byApogee = userRepository.findByCodeApogee(codeApogee);
        if (byApogee != null) {
            // Déjà rattaché au groupe sélectionné → OK
            if (byApogee.getGroup() != null && byApogee.getGroup().getId().equals(group.getId())) {
                return true;
            }
            // Rattaché à un autre groupe → refus
            return false;
        }

        // 3) Aucun conflit → autorisé
        return true;
    }
}