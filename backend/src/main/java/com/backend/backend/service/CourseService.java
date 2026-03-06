package com.backend.backend.service;

import com.backend.backend.dao.entities.Course;
import com.backend.backend.dto.course.CourseCreateDTO;
import com.backend.backend.dto.course.CourseResponseDTO;

import java.util.List;

public interface CourseService {

    CourseResponseDTO createCourse(CourseCreateDTO course);

    Course getCourseById(Long id);

    List<Course> getAllCourses();

    Course updateCourse(Long id, Course course);

    void deleteCourse(Long id);
}
