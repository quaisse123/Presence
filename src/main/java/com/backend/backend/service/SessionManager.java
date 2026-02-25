package com.backend.backend.service;

import com.backend.backend.dao.entities.Session;
import com.backend.backend.dao.repositories.SessionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class SessionManager implements SessionService {

    @Autowired
    private SessionRepository sessionRepository;

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
        return null;
    }

    @Override
    public Session updateSession(Long id, Session session) {
        return null;
    }

    @Override
    public void deleteSession(Long id) {

    }
}
