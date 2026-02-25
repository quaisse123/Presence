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

    @GetMapping(value = "/all", produces = "text/html; charset=utf-8")
    public String getAllForTesting() {
        List<User> users = userRepository.findAll();
        List<Course> courses = courseRepository.findAll();
        List<Session> sessions = sessionRepository.findAll();
        List<Attendance> attendances = attendanceRepository.findAll();

        StringBuilder sb = new StringBuilder();
        sb.append("<html><head><meta charset='utf-8'><title>Test Data</title>");
        sb.append("<style>body{font-family:Arial,Helvetica,sans-serif}table{border-collapse:collapse;margin-bottom:20px;width:100%}th,td{border:1px solid #ddd;padding:8px;text-align:left}th{background:#f4f4f4}</style>");
        sb.append("</head><body>");
        sb.append("<h1>Données de test</h1>");

        // Users
        sb.append("<h2>Utilisateurs (" + users.size() + ")</h2>");
        sb.append("<table><tr><th>ID</th><th>Email</th><th>Role</th><th>Biometric</th></tr>");
        for (User u : users) {
            sb.append("<tr>");
            sb.append("<td>" + (u.getId() == null ? "-" : u.getId()) + "</td>");
            sb.append("<td>" + escape(u.getEmail()) + "</td>");
            sb.append("<td>" + (u.getRole() == null ? "-" : u.getRole()) + "</td>");
            sb.append("<td>" + (u.getBiometricToken() == null ? "" : escape(u.getBiometricToken())) + "</td>");
            sb.append("</tr>");
        }
        sb.append("</table>");

        // Courses
        sb.append("<h2>Cours (" + courses.size() + ")</h2>");
        sb.append("<table><tr><th>ID</th><th>Code</th><th>Title</th></tr>");
        for (Course c : courses) {
            sb.append("<tr>");
            sb.append("<td>" + (c.getId() == null ? "-" : c.getId()) + "</td>");
            sb.append("<td>" + escape(c.getCode()) + "</td>");
            sb.append("<td>" + escape(c.getTitle()) + "</td>");
            sb.append("</tr>");
        }
        sb.append("</table>");

        // Sessions
        sb.append("<h2>Sessions (" + sessions.size() + ")</h2>");
        sb.append("<table><tr><th>ID</th><th>Course</th><th>Professor</th><th>Start</th><th>End</th><th>QR Token</th></tr>");
        for (Session s : sessions) {
            sb.append("<tr>");
            sb.append("<td>" + (s.getId() == null ? "-" : s.getId()) + "</td>");
            sb.append("<td>" + (s.getCourse() == null ? "" : escape(s.getCourse().getCode())) + "</td>");
            sb.append("<td>" + (s.getProfessor() == null ? "" : escape(s.getProfessor().getEmail())) + "</td>");
            sb.append("<td>" + (s.getStartTime() == null ? "" : s.getStartTime()) + "</td>");
            sb.append("<td>" + (s.getEndTime() == null ? "" : s.getEndTime()) + "</td>");
            sb.append("<td>" + (s.getQrCodeToken() == null ? "" : escape(s.getQrCodeToken())) + "</td>");
            sb.append("</tr>");
        }
        sb.append("</table>");

        // Attendances
        sb.append("<h2>Présences (" + attendances.size() + ")</h2>");
        sb.append("<table><tr><th>ID</th><th>Student</th><th>Session ID</th><th>Status</th><th>Scan Time</th><th>Device</th></tr>");
        for (Attendance a : attendances) {
            sb.append("<tr>");
            sb.append("<td>" + (a.getId() == null ? "-" : a.getId()) + "</td>");
            sb.append("<td>" + (a.getStudent() == null ? "" : escape(a.getStudent().getEmail())) + "</td>");
            sb.append("<td>" + (a.getSession() == null ? "" : (a.getSession().getId() == null ? "-" : a.getSession().getId())) + "</td>");
            sb.append("<td>" + (a.getStatus() == null ? "" : a.getStatus()) + "</td>");
            sb.append("<td>" + (a.getScanTime() == null ? "" : a.getScanTime()) + "</td>");
            sb.append("<td>" + (a.getDeviceId() == null ? "" : escape(a.getDeviceId())) + "</td>");
            sb.append("</tr>");
        }
        sb.append("</table>");

        sb.append("</body></html>");
        return sb.toString();
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}
