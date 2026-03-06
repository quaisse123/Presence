package com.backend.backend.service;

import com.backend.backend.dao.entities.Course;
import com.backend.backend.dao.repositories.CourseRepository;
import com.backend.backend.dto.course.CourseCreateDTO;
import com.backend.backend.dto.course.CourseDTO;
import com.backend.backend.dto.course.CourseResponseDTO;
import com.backend.backend.dto.course.CourseSessionDTO;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class CourseManager implements CourseService {

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private ModelMapper modelMapper;

    @Override
    public CourseResponseDTO createCourse(CourseCreateDTO createDTO) {
        Course course = new Course() ;
        course.setCode(createDTO.getCode());
        course.setTitle(createDTO.getTitle());
        Course CourseEntitiy = courseRepository.save(course);
        CourseResponseDTO responseDTO = modelMapper.map(CourseEntitiy, CourseResponseDTO.class);
        return responseDTO;
    }

    @Override
    public Course getCourseById(Long id) {
        return null;
    }

    @Override
    public List<Course> getAllCourses() {
        return courseRepository.findAll();
    }

    public Page<CourseDTO> getAllCourseSummaries(int page, int size) {
        Page<Course> courses = courseRepository.findAllByOrderByIdDesc(PageRequest.of(page, size));
        return courses.map(c -> {
            CourseDTO dto = modelMapper.map(c, CourseDTO.class);
            if (c.getSessions() != null) {
                dto.setSessions(c.getSessions().stream()
                        .map(s -> {
                            CourseSessionDTO sDto = new CourseSessionDTO();
                            sDto.setId(s.getId());
                            sDto.setDate(s.getStartTime() != null ? s.getStartTime().toLocalDate() : null);
                            sDto.setStartTime(s.getStartTime());
                            sDto.setEndTime(s.getEndTime());
                            sDto.setSalle(s.getSalle());
                            return sDto;
                        })
                        .toList());
            }
            return dto;
        });
    }

    @Override
    public Course updateCourse(Long id, Course course) {
        return null;
    }

    @Override
    public void deleteCourse(Long id) {
        courseRepository.deleteById(id);
    }

    public boolean isCourseCodeAvailable(String code) {
        return !courseRepository.existsByCode(code);
    }
}
