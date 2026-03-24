package com.backend.backend.service;

import com.backend.backend.dao.entities.Attendance;
import com.backend.backend.dao.entities.AttendanceStatus;
import com.backend.backend.dao.entities.Role;
import com.backend.backend.dao.entities.Session;
import com.backend.backend.dao.entities.User;
import com.backend.backend.dao.repositories.AttendanceRepository;
import com.backend.backend.dao.repositories.SessionRepository;
import com.backend.backend.dao.repositories.UserRepository;
import com.backend.backend.dto.attendance.AttendanceMyResponseDTO;
import com.backend.backend.dto.attendance.AttendanceResponseDTO;
import com.backend.backend.dto.attendance.AttendanceScanRequestDTO;
import com.backend.backend.dto.attendance.AttendanceSummaryDTO;
import com.backend.backend.service.Jwt.JwtService;

import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Service
public class AttendanceManager implements AttendanceService {

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private UserService userService; // Service pour récupérer les informations de l'utilisateur

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    @Autowired
    ModelMapper modelMapper;
    
    @Override
    public Attendance createAttendance(Attendance attendance) {
        return null;
    }

    @Override
    public Attendance getAttendanceById(Long id) {
        return null;
    }

    @Override
    public List<Attendance> getAllAttendances() {
        return null;
    }

    @Override
    public Attendance updateAttendance(Long id, Attendance attendance) {
        return null;
    }

    @Override
    public void deleteAttendance(Long id) {

    }

    @Override
    public AttendanceResponseDTO scanAttendance(AttendanceScanRequestDTO request) {
        if (request == null || request.getQrCodeToken() == null || request.getStudentId() == null) {
            return buildErrorResponse("Requête invalide: qrCodeToken et studentId sont obligatoires.");
        }

        if (!jwtService.validateToken(request.getQrCodeToken())) {
            return buildErrorResponse("QR invalide ou expiré.");
        }

        Map<String, Object> claims;
        try {
            claims = jwtService.extractClaims(request.getQrCodeToken());
        } catch (Exception e) {
            return buildErrorResponse("QR invalide ou expiré.");
        }

        Object tokenType = claims.get("type");
        if (!"attendance_qr".equals(tokenType)) {
            return buildErrorResponse("Type de QR invalide.");
        }

        Long sessionId = toLong(claims.get("sessionId"));
        if (sessionId == null) {
            return buildErrorResponse("QR invalide: sessionId manquant.");
        }

        Session session = sessionRepository.findById(sessionId).orElse(null);

        // Vérifier si la session est active (en cours)
        if (session == null || session.getStartTime().isAfter(LocalDateTime.now())
                || session.getEndTime().isBefore(LocalDateTime.now())) {
            return buildErrorResponse("Session non trouvée ou non active.");
        }

        boolean isWithinGeofence = isLocationValid();
        if (!isWithinGeofence) {
            return buildErrorResponse("Hors zone autorisée pour le scan.");
        }

        AttendanceStatus status = getAttendanceStatus();

        User student = userService.getUserById(request.getStudentId());
        if (student == null) {
            return buildErrorResponse("Etudiant introuvable pour l'ID fourni.");
        }
        if (student.getRole() != Role.STUDENT) {
            return buildErrorResponse("L'ID fourni ne correspond pas a un etudiant.");
        }
        if (student.getGroup() == null || session.getGroup() == null || !student.getGroup().getId().equals(session.getGroup().getId())) {
            return buildErrorResponse("Vous n'etes pas inscrit dans le groupe correspondant a ce QR code."); // Sécurité supplémentaire pour éviter les scans croisés entre groupes
        }

        Attendance attendance = new Attendance();
        attendance.setScanTime(request.getScanTime() != null ? request.getScanTime() : LocalDateTime.now());
        attendance.setStatus(status);
        attendance.setIsOfflineSync(false);
        attendance.setDeviceId(request.getDeviceId());
        attendance.setScanLatitude(request.getScanLatitude());
        attendance.setScanLongitude(request.getScanLongitude());
        attendance.setStudent(student);
        attendance.setSession(session);
        attendanceRepository.save(attendance);

        AttendanceResponseDTO response = buildSuccessResponse(attendance, student, session);

        return response;

    }

    @Override
    public AttendanceMyResponseDTO getStudentAttendances(String period, String status, String search, String studentEmail) {
        AttendanceMyResponseDTO result = new AttendanceMyResponseDTO();

        // On récupère l'étudiant connecté à partir de son email JWT.
        User student = userRepository.findByEmail(studentEmail);
        if (student == null || student.getRole() != Role.STUDENT) {
            result.setTotalSessions(0);
            result.setAttendedSessions(0);
            result.setMissedSessions(0);
            result.setItems(new ArrayList<>());
            return result;
        }

        // Filtre 1: période (LAST_WEEK, LAST_MONTH, ALL).
        LocalDateTime[] dateRange = buildDateRange(period);
        LocalDateTime startDate = dateRange[0];
        LocalDateTime endDate = dateRange[1];

        // Filtre 2: statut (PRESENT, LATE, ABSENT).
        AttendanceStatus parsedStatus = parseStatus(status);

        // Filtre 3: recherche texte (course title / course code / salle).
        String normalizedSearch = normalizeSearch(search);

        // Pipeline final: student + filtres optionnels.
        List<Attendance> attendances = attendanceRepository.findStudentAttendancesWithFilters(
                student.getId(),
                startDate,
                endDate,
                parsedStatus,
                normalizedSearch
        );

        int[] stats = computeStudentStats(student, period);

        List<AttendanceSummaryDTO> items = attendances.stream()
            .map(this::toSummaryDTO)
            .toList();

        result.setTotalSessions(stats[0]);
        result.setAttendedSessions(stats[1]);
        result.setMissedSessions(stats[2]);
        result.setItems(items);
        return result;
    }





    // Helpers =============================================================
    
    private AttendanceSummaryDTO toSummaryDTO(Attendance attendance) {
        AttendanceSummaryDTO dto = new AttendanceSummaryDTO();
        dto.setId(attendance.getId());
        dto.setScanTime(attendance.getScanTime());
        dto.setStatus(attendance.getStatus());
        dto.setStudentId(attendance.getStudent() != null ? attendance.getStudent().getId() : null);
        dto.setSessionId(attendance.getSession() != null ? attendance.getSession().getId() : null);

        if (attendance.getSession() != null) {
            dto.setSalle(attendance.getSession().getSalle());
            dto.setSessionStartTime(attendance.getSession().getStartTime());
            dto.setSessionEndTime(attendance.getSession().getEndTime());
            if (attendance.getSession().getCourse() != null) {
                dto.setCourseTitle(attendance.getSession().getCourse().getTitle());
                dto.setCourseCode(attendance.getSession().getCourse().getCode());
            }
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

    private AttendanceResponseDTO buildErrorResponse(String message) {
        AttendanceResponseDTO response = new AttendanceResponseDTO();
        response.setSuccess(false);
        response.setMessage(message);
        return response;
    }

    private AttendanceResponseDTO buildSuccessResponse(Attendance attendance, User student, Session session) {
        AttendanceResponseDTO response = modelMapper.map(attendance, AttendanceResponseDTO.class);
        response.setStudentId(student.getId());
        response.setSessionId(session.getId());

        response.setStudentEmail(student.getEmail());
        response.setStudentFirstName(extractFirstNameFromEmail(student.getEmail()));

        if (session.getCourse() != null) {
            response.setSessionTitle(session.getCourse().getTitle());
            response.setCourseCode(session.getCourse().getCode());
        }
        response.setSessionStartTime(session.getStartTime());
        response.setSessionEndTime(session.getEndTime());
        response.setSalle(session.getSalle());

        if (session.getProfessor() != null) {
            response.setProfessorName(extractFirstNameFromEmail(session.getProfessor().getEmail()));
        }

        response.setSuccess(true);
        response.setMessage("Présence enregistrée avec succès.");
        return response;
    }

    private int[] computeStudentStats(User student, String period) {
        if (student == null || student.getGroup() == null) {
            return new int[]{0, 0, 0};
        }

        // Etape 1: construire la période demandée.
        LocalDateTime[] dateRange = buildDateRange(period);
        LocalDateTime startDate = dateRange[0];
        LocalDateTime endDate = dateRange[1];
        LocalDateTime now = LocalDateTime.now();

        // Etape 2: compter les sessions passées du groupe dans la période.
        long totalSessions = sessionRepository.countPastSessionsByGroupWithPeriod(
                student.getGroup().getId(),
                now,
                startDate,
                endDate
        );

        // Etape 3: compter les sessions où l'étudiant a assisté (PRESENT ou LATE).
        long attendedSessions = attendanceRepository.countAttendedSessionsByStudentWithPeriod(
                student.getId(),
                now,
                startDate,
                endDate,
                Arrays.asList(AttendanceStatus.PRESENT, AttendanceStatus.LATE)
        );

        // Etape 4: séances ratées = total - attended.
        long missedSessions = totalSessions - attendedSessions;
        if (missedSessions < 0) {
            missedSessions = 0;
        }

        return new int[]{(int) totalSessions, (int) attendedSessions, (int) missedSessions};
    }

    private String extractFirstNameFromEmail(String email) {
        if (email == null || email.isBlank()) {
            return "Etudiant";
        }

        String localPart = email.split("@")[0];
        String[] tokens = localPart.split("[._-]");
        String raw = tokens.length > 0 ? tokens[0] : localPart;
        if (raw.isBlank()) {
            return "Etudiant";
        }

        String lower = raw.toLowerCase();
        return Character.toUpperCase(lower.charAt(0)) + lower.substring(1);
    }

    private AttendanceStatus getAttendanceStatus() {
        // TODO Auto-generated method stub
        return AttendanceStatus.PRESENT;
    }

    private boolean isLocationValid() {
        // TODO Auto-generated method stub
        return true;
    }

    private Long toLong(Object value) {
        if (value instanceof Number number) {
            return number.longValue();
        }
        if (value instanceof String str) {
            try {
                return Long.parseLong(str);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }
}
