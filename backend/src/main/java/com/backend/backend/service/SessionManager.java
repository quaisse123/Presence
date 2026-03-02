package com.backend.backend.service;

import com.backend.backend.dao.entities.Session;
import com.backend.backend.dao.repositories.SessionRepository;
import com.backend.backend.dto.session.SessionSummaryDTO;

import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
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

    public List<SessionSummaryDTO> getAllSessionSummaries() {
        List<Session> sessions = sessionRepository.findAll();
        return sessions.stream()
                .map(this::toSummaryDTO)
                .collect(Collectors.toList());
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
}
