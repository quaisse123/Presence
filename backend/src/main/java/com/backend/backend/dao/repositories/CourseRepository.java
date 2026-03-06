package com.backend.backend.dao.repositories;

import com.backend.backend.dao.entities.Course;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CourseRepository extends JpaRepository<Course, Long> {

    Page<Course> findAllByOrderByIdDesc(PageRequest of);

    boolean existsByCode(String code);

    

}
