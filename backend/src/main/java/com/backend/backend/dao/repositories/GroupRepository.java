package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Group;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GroupRepository extends JpaRepository<Group, Long> {
    List<Group> findByFiliere(String filiere);
    List<Group> findByLevel(String level);
    List<Group> findBySection(String section);
    List<Group> findByFiliereAndLevel(String filiere, String level);
}
