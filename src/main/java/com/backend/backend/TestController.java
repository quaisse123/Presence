package com.backend.backend;

import com.backend.backend.dao.entities.Attendance;
import com.backend.backend.dao.entities.Course;
import com.backend.backend.dao.entities.Session;
import com.backend.backend.dao.entities.User;
import com.backend.backend.dao.repositories.AttendanceRepository;
import com.backend.backend.dao.repositories.CourseRepository;
import com.backend.backend.dao.repositories.SessionRepository;
import com.backend.backend.dao.repositories.UserRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/test")
public class TestController {

    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final SessionRepository sessionRepository;
    private final AttendanceRepository attendanceRepository;

    public TestController(UserRepository userRepository,
                          CourseRepository courseRepository,
                          SessionRepository sessionRepository,
                          AttendanceRepository attendanceRepository) {
        this.userRepository = userRepository;
        this.courseRepository = courseRepository;
        this.sessionRepository = sessionRepository;
        this.attendanceRepository = attendanceRepository;
    }

    @GetMapping("/")
    public String test() {
        return "<h1>Hello World</h1><p>Ça marche !</p>";
    }


    @GetMapping(value = "/all", produces = "application/json; charset=utf-8")
    public Map<String, Object> getAllForTesting() {
        List<User> users = userRepository.findAll();
        List<Course> courses = courseRepository.findAll();
        List<Session> sessions = sessionRepository.findAll();
        List<Attendance> attendances = attendanceRepository.findAll();

        Map<String, Object> result = new HashMap<>();
        result.put("users", users);
        result.put("courses", courses);
        result.put("sessions", sessions);
        result.put("attendances", attendances);
        return result;
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}
