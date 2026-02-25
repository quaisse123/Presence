package com.backend.backend.service;

import com.backend.backend.dao.entities.Course;
import java.util.List;

public interface CourseService {

    Course createCourse(Course course);

    Course getCourseById(Long id);

    List<Course> getAllCourses();

    Course updateCourse(Long id, Course course);

    void deleteCourse(Long id);
}
