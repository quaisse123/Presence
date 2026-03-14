package com.backend.backend.service;

import com.backend.backend.dao.entities.Attendance;
import com.backend.backend.dao.entities.AttendanceStatus;
import com.backend.backend.dao.entities.Role;
import com.backend.backend.dao.entities.Session;
import com.backend.backend.dao.entities.User;
import com.backend.backend.dao.repositories.AttendanceRepository;
import com.backend.backend.dao.repositories.SessionRepository;
import com.backend.backend.dto.attendance.AttendanceResponseDTO;
import com.backend.backend.dto.attendance.AttendanceScanRequestDTO;

import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AttendanceManager implements AttendanceService {

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private UserService userService; // Service pour récupérer les informations de l'utilisateur

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
            AttendanceResponseDTO response = new AttendanceResponseDTO();
            response.setSuccess(false);
            response.setMessage("Requête invalide: qrCodeToken et studentId sont obligatoires.");
            return response;
        }

        Session session = sessionRepository.getSessionByQrCodeToken(request.getQrCodeToken());

        // Vérifier si la session est active (en cours)
        // if (session == null || session.getStartTime().isAfter(LocalDateTime.now())
        //         || session.getEndTime().isBefore(LocalDateTime.now())) {
        //     AttendanceResponseDTO response = new AttendanceResponseDTO();
        //     response.setSuccess(false);
        //     response.setMessage("Session non trouvée ou non active.");
        //     return response;
        // }

        boolean isWithinGeofence = isLocationValid();
        if (!isWithinGeofence) {
            AttendanceResponseDTO response = new AttendanceResponseDTO();
            response.setSuccess(false);
            response.setMessage("Hors zone autorisée pour le scan.");
            return response;
        }

        AttendanceStatus status = getAttendanceStatus();

        User student = userService.getUserById(request.getStudentId());
        if (student == null) {
            AttendanceResponseDTO response = new AttendanceResponseDTO();
            response.setSuccess(false);
            response.setMessage("Etudiant introuvable pour l'ID fourni.");
            return response;
        }
        if (student.getRole() != Role.STUDENT) {
            AttendanceResponseDTO response = new AttendanceResponseDTO();
            response.setSuccess(false);
            response.setMessage("L'ID fourni ne correspond pas a un etudiant.");
            return response;
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

        AttendanceResponseDTO response = modelMapper.map(attendance, AttendanceResponseDTO.class);
        response.setStudentId(student.getId());
        response.setSessionId(session.getId());
        response.setSuccess(true);
        response.setMessage("Présence enregistrée avec succès.");

        return response;

    }

    private AttendanceStatus getAttendanceStatus() {
        // TODO Auto-generated method stub
        return AttendanceStatus.PRESENT;
    }

    private boolean isLocationValid() {
        // TODO Auto-generated method stub
        return true;
    }
}
