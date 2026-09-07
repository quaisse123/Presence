package com.backend.backend.service;

import com.backend.backend.dao.entities.Attendance;
import com.backend.backend.dao.entities.AttendanceStatus;
import com.backend.backend.dao.entities.Course;
import com.backend.backend.dao.entities.Group;
import com.backend.backend.dao.entities.Role;
import com.backend.backend.dao.entities.Session;
import com.backend.backend.dao.entities.User;
import com.backend.backend.dao.repositories.AttendanceRepository;
import com.backend.backend.dao.repositories.CourseRepository;
import com.backend.backend.dao.repositories.GroupRepository;
import com.backend.backend.dao.repositories.SessionRepository;
import com.backend.backend.dao.repositories.UserRepository;
import com.backend.backend.dto.course.CourseSummaryDTO;
import com.backend.backend.dto.group.GroupDTO;
import com.backend.backend.dto.session.SessionAttendanceDetailDTO;
import com.backend.backend.dto.session.SessionCreateDTO;
import com.backend.backend.dto.session.SessionDTO;
import com.backend.backend.dto.session.SessionGroupDTO;
import com.backend.backend.dto.session.SessionResponseDTO;
import com.backend.backend.dto.session.SessionSummaryDTO;
import com.backend.backend.dto.session.StudentSessionHistoryItemDTO;
import com.backend.backend.dto.session.StudentSessionHistoryResponseDTO;

import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class SessionManager implements SessionService {

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private GroupRepository groupRepository;

    @Autowired
    private ModelMapper modelMapper;

    @Override
    public Session createSession(Session session) {
        return sessionRepository.save(session);
    }

    @Override
    public Session getSessionById(Long id) {
        return sessionRepository.findById(id).orElse(null);
    }

    @Override
    public List<Session> getAllSessions() {
        return sessionRepository.findAll();
    }

    // ── Session Summaries ──────────────────────────────────────────────────
    
    public Page<SessionSummaryDTO> getAllSessionSummaries(int page,int size) {
        Page<Session> sessions = sessionRepository.findAllByOrderByStartTimeDesc(PageRequest.of(page,size));
        return sessions.map(this::toSummaryDTO);
    }

    private SessionSummaryDTO toSummaryDTO(Session session) {
        SessionSummaryDTO dto = new SessionSummaryDTO();
        dto.setId(session.getId());
        dto.setCourseTitle(session.getCourse().getTitle());
        dto.setCourseCode(session.getCourse().getCode());
        dto.setCourseId(session.getCourse().getId());
        dto.setSalle(session.getSalle());
        dto.setStartTime(session.getStartTime());
        dto.setEndTime(session.getEndTime());
        dto.setDescription(session.getDescription());
        dto.setAttendance(session.getAttendances() != null ? session.getAttendances().size() : 0);
        dto.setTotalStudents(session.getGroup() != null ? session.getGroup().getTotalStudents() : 0);
        return dto;
    }

    public StudentSessionHistoryResponseDTO getStudentSessionHistory(
            String period,
            String status,
            String search,
            String studentEmail
    ) {
        StudentSessionHistoryResponseDTO result = new StudentSessionHistoryResponseDTO();

        User student = userRepository.findByEmail(studentEmail);
        if (student == null || student.getRole() != Role.STUDENT || student.getGroup() == null) {
            result.setTotalSessions(0);
            result.setAttendedSessions(0);
            result.setMissedSessions(0);
            result.setItems(new ArrayList<>());
            return result;
        }

        LocalDateTime[] dateRange = buildDateRange(period);
        LocalDateTime startDate = dateRange[0];
        LocalDateTime endDate = dateRange[1];
        LocalDateTime now = LocalDateTime.now();

        AttendanceStatus requestedStatus = parseStatus(status);
        String normalizedSearch = normalizeSearch(search);

        List<Session> sessions = sessionRepository.findStudentSessionsWithFilters(
                student.getGroup().getId(),
                now,
                startDate,
                endDate,
                normalizedSearch
        );

        List<Long> sessionIds = sessions.stream().map(Session::getId).toList();
        Map<Long, Attendance> attendanceBySessionId = new HashMap<>();
        if (!sessionIds.isEmpty()) {
            List<Attendance> attendances = attendanceRepository.findByStudent_IdAndSession_IdIn(
                    student.getId(),
                    sessionIds
            );
            for (Attendance attendance : attendances) {
                if (attendance.getSession() != null) {
                    attendanceBySessionId.put(attendance.getSession().getId(), attendance);
                }
            }
        }

        List<StudentSessionHistoryItemDTO> items = sessions.stream()
                .map(session -> toStudentSessionItemDTO(session, attendanceBySessionId.get(session.getId())))
                .filter(item -> requestedStatus == null || item.getStatus() == requestedStatus)
                .toList();

        int[] stats = computeStudentStats(student, period);

        result.setTotalSessions(stats[0]);
        result.setAttendedSessions(stats[1]);
        result.setMissedSessions(stats[2]);
        result.setItems(items);
        return result;
    }

    // ───────────────────────────────────────────────────────────────────────
    
    @Override
    public Session updateSession(Long id, Session session) {
        Session existing = sessionRepository.findById(id).orElse(null);
        if (existing == null) {
            return null;
        }
        if (session.getStartTime() != null) existing.setStartTime(session.getStartTime());
        if (session.getEndTime() != null) existing.setEndTime(session.getEndTime());
        if (session.getSalle() != null) existing.setSalle(session.getSalle());
        if (session.getDescription() != null) existing.setDescription(session.getDescription());
        if (session.getLatitude() != null) existing.setLatitude(session.getLatitude());
        if (session.getLongitude() != null) existing.setLongitude(session.getLongitude());
        if (session.getRadiusInMeters() != null) existing.setRadiusInMeters(session.getRadiusInMeters());
        return sessionRepository.save(existing);
    }

    @Override
    public void deleteSession(Long id) {
        sessionRepository.deleteById(id);
    }

    // ── Session Creation (professor) ──────────────────────────────────────

    /**
     * Liste tous les groupes (pour le formulaire de création de session).
     */
    public List<GroupDTO> getAllGroups() {
        return groupRepository.findAll().stream()
                .map(g -> {
                    GroupDTO dto = new GroupDTO();
                    dto.setId(g.getId());
                    dto.setLevel(g.getLevel());
                    dto.setSection(g.getSection());
                    dto.setFiliere(g.getFiliere());
                    dto.setTotalStudents(g.getTotalStudents());
                    return dto;
                })
                .collect(Collectors.toList());
    }

    /**
     * Crée une session à partir du DTO envoyé par le professeur.
     * Le professeur est identifié par son email (issu du JWT).
     * Le qrCodeToken est généré automatiquement (UUID).
     */
    public SessionResponseDTO createSessionFromDTO(SessionCreateDTO dto, String professorEmail) {
        if (dto == null || dto.getCourseId() == null || dto.getGroupId() == null) {
            throw new RuntimeException("courseId et groupId sont obligatoires.");
        }
        if (dto.getStartTime() == null || dto.getEndTime() == null) {
            throw new RuntimeException("startTime et endTime sont obligatoires.");
        }
        if (!dto.getEndTime().isAfter(dto.getStartTime())) {
            throw new RuntimeException("endTime doit être après startTime.");
        }

        Course course = courseRepository.findById(dto.getCourseId())
                .orElseThrow(() -> new RuntimeException("Cours introuvable: " + dto.getCourseId()));
        Group group = groupRepository.findById(dto.getGroupId())
                .orElseThrow(() -> new RuntimeException("Groupe introuvable: " + dto.getGroupId()));
        User professor = userRepository.findByEmail(professorEmail);
        if (professor == null || professor.getRole() != Role.PROFESSOR) {
            throw new RuntimeException("Professeur introuvable.");
        }

        Session session = new Session();
        session.setStartTime(dto.getStartTime());
        session.setEndTime(dto.getEndTime());
        session.setLatitude(dto.getLatitude());
        session.setLongitude(dto.getLongitude());
        session.setRadiusInMeters(dto.getRadiusInMeters() != null ? dto.getRadiusInMeters() : 50.0);
        session.setSalle(dto.getSalle());
        session.setDescription(dto.getDescription());
        session.setCourse(course);
        session.setGroup(group);
        session.setProfessor(professor);
        session.setQrCodeToken(UUID.randomUUID().toString());

        Session saved = sessionRepository.save(session);

        SessionResponseDTO response = new SessionResponseDTO();
        response.setId(saved.getId());
        response.setStartTime(saved.getStartTime());
        response.setEndTime(saved.getEndTime());
        response.setQrCodeToken(saved.getQrCodeToken());
        response.setLatitude(saved.getLatitude());
        response.setLongitude(saved.getLongitude());
        response.setRadiusInMeters(saved.getRadiusInMeters());
        response.setCourseId(saved.getCourse().getId());
        response.setProfessorId(saved.getProfessor().getId());
        return response;
    }

    /**
     * Ferme une session en mettant endTime à maintenant.
     */
    public SessionResponseDTO closeSession(Long id) {
        Session session = sessionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Session introuvable: " + id));
        session.setEndTime(LocalDateTime.now());
        Session saved = sessionRepository.save(session);

        SessionResponseDTO response = new SessionResponseDTO();
        response.setId(saved.getId());
        response.setStartTime(saved.getStartTime());
        response.setEndTime(saved.getEndTime());
        response.setQrCodeToken(saved.getQrCodeToken());
        response.setLatitude(saved.getLatitude());
        response.setLongitude(saved.getLongitude());
        response.setRadiusInMeters(saved.getRadiusInMeters());
        response.setCourseId(saved.getCourse().getId());
        response.setProfessorId(saved.getProfessor().getId());
        return response;
    }

    // ── Session Details ───────────────────────────────────────────────────

    @Override
    public SessionDTO getSessionDetail(Long id) {
        Session session = sessionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Session not found: " + id));
        return toDetailDTO(session);
    }

    private SessionDTO toDetailDTO(Session session) {
        SessionDTO dto = new SessionDTO();

        // Flat fields mapped via ModelMapper
        modelMapper.map(session, dto);

        // Manual – Course
        if (session.getCourse() != null) {
            dto.setCourse(modelMapper.map(session.getCourse(), CourseSummaryDTO.class));
        }

        // Manual – Group
        if (session.getGroup() != null) {
            dto.setGroup(modelMapper.map(session.getGroup(), SessionGroupDTO.class));
        }

        // Manual – Attendances (student.email must be resolved manually)
        if (session.getAttendances() != null) {
            List<SessionAttendanceDetailDTO> attendanceDTOs = session.getAttendances().stream()
                    .map(a -> {
                        SessionAttendanceDetailDTO aDto = new SessionAttendanceDetailDTO();
                        aDto.setId(a.getId());
                        aDto.setScanTime(a.getScanTime());
                        aDto.setStatus(a.getStatus());
                        aDto.setStudentEmail(
                                a.getStudent() != null ? a.getStudent().getEmail() : null);
                        return aDto;
                    })
                    .collect(Collectors.toList());
            dto.setAttendances(attendanceDTOs);
        } else {
            dto.setAttendances(Collections.emptyList());
        }

        return dto;
    }

    private StudentSessionHistoryItemDTO toStudentSessionItemDTO(Session session, Attendance attendance) {
        StudentSessionHistoryItemDTO dto = new StudentSessionHistoryItemDTO();
        dto.setSessionId(session.getId());
        dto.setSalle(session.getSalle());
        dto.setSessionStartTime(session.getStartTime());
        dto.setSessionEndTime(session.getEndTime());

        if (session.getCourse() != null) {
            dto.setCourseTitle(session.getCourse().getTitle());
            dto.setCourseCode(session.getCourse().getCode());
        }

        if (session.getProfessor() != null) {
            dto.setProfessorName(extractFirstNameFromEmail(session.getProfessor().getEmail()));
        }

        if (attendance != null) {
            dto.setStatus(attendance.getStatus());
            dto.setScanTime(attendance.getScanTime());
        } else {
            dto.setStatus(AttendanceStatus.ABSENT);
            dto.setScanTime(null);
        }

        return dto;
    }

    private LocalDateTime[] buildDateRange(String period) {
        LocalDateTime now = LocalDateTime.now();

        if (period == null || period.isBlank() || period.equalsIgnoreCase("ALL")) {
            return new LocalDateTime[]{null, null};
        }

        if (period.equalsIgnoreCase("LAST_WEEK")) {
            return new LocalDateTime[]{now.minus(7, ChronoUnit.DAYS), now};
        }

        if (period.equalsIgnoreCase("LAST_MONTH")) {
            return new LocalDateTime[]{now.minus(30, ChronoUnit.DAYS), now};
        }

        return new LocalDateTime[]{null, null};
    }

    private AttendanceStatus parseStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }

        try {
            return AttendanceStatus.valueOf(status.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private String normalizeSearch(String search) {
        if (search == null || search.isBlank()) {
            return null;
        }
        return search.trim();
    }

    private int[] computeStudentStats(User student, String period) {
        LocalDateTime[] dateRange = buildDateRange(period);
        LocalDateTime startDate = dateRange[0];
        LocalDateTime endDate = dateRange[1];
        LocalDateTime now = LocalDateTime.now();

        long totalSessions = sessionRepository.countPastSessionsByGroupWithPeriod(
                student.getGroup().getId(),
                now,
                startDate,
                endDate
        );

        long attendedSessions = attendanceRepository.countAttendedSessionsByStudentWithPeriod(
                student.getId(),
                now,
                startDate,
                endDate,
                Arrays.asList(AttendanceStatus.PRESENT, AttendanceStatus.LATE)
        );

        long missedSessions = totalSessions - attendedSessions;
        if (missedSessions < 0) {
            missedSessions = 0;
        }

        return new int[]{(int) totalSessions, (int) attendedSessions, (int) missedSessions};
    }

    private String extractFirstNameFromEmail(String email) {
        if (email == null || email.isBlank()) {
            return "Professor";
        }

        String localPart = email.split("@")[0];
        String[] tokens = localPart.split("[._-]");
        String raw = tokens.length > 0 ? tokens[0] : localPart;
        if (raw.isBlank()) {
            return "Professor";
        }

        String lower = raw.toLowerCase();
        return Character.toUpperCase(lower.charAt(0)) + lower.substring(1);
    }


    // Qrcode methods will
     

}
