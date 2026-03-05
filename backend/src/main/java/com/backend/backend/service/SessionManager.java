package com.backend.backend.service;

import com.backend.backend.dao.entities.Session;
import com.backend.backend.dao.repositories.SessionRepository;
import com.backend.backend.dto.course.CourseSummaryDTO;
import com.backend.backend.dto.session.SessionAttendanceDetailDTO;
import com.backend.backend.dto.session.SessionDTO;
import com.backend.backend.dto.session.SessionGroupDTO;
import com.backend.backend.dto.session.SessionSummaryDTO;

import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class SessionManager implements SessionService {

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private ModelMapper modelMapper;

    @Override
    public Session createSession(Session session) {
        return null;
    }

    @Override
    public Session getSessionById(Long id) {
        return null;
    }

    @Override
    public List<Session> getAllSessions() {
        return sessionRepository.findAll();
    }
    
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

    @Override
    public Session updateSession(Long id, Session session) {
        return null;
    }

    @Override
    public void deleteSession(Long id) {

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
}
