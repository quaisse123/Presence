package com.backend.backend.web;

import com.backend.backend.dto.course.CourseCreateDTO;
import com.backend.backend.dto.course.CourseDTO;
import com.backend.backend.dto.course.CourseResponseDTO;
import com.backend.backend.service.CourseManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/courses")
public class CourseController {

    @Autowired
    private CourseManager courseManager;

    @GetMapping
    public Page<CourseDTO> getCourses(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return courseManager.getAllCourseSummaries(page, size);
    }

    @PostMapping
    public CourseResponseDTO createNewCourse(@RequestBody CourseCreateDTO body) {
        CourseResponseDTO responseDTO = courseManager.createCourse(body);
        return responseDTO;
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT) // force 204
    public void deleteCourse(@PathVariable Long id) {
        courseManager.deleteCourse(id);
    }

    // check code availability
    @GetMapping("/check-code")
    public boolean checkCourseCodeAvailability(@RequestParam String code) {
        return courseManager.isCourseCodeAvailable(code);
    }

}
