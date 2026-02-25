package com.backend.backend.service;

import com.backend.backend.dao.entities.Session;
import java.util.List;

public interface SessionService {

    Session createSession(Session session);

    Session getSessionById(Long id);

    List<Session> getAllSessions();

    Session updateSession(Long id, Session session);

    void deleteSession(Long id);
}
