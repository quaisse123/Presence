package com.backend.backend.web;

import com.backend.backend.dto.session.SessionSummaryDTO;
import com.backend.backend.service.SessionManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/sessions")
public class SessionController {

    @Autowired
    private SessionManager sessionManager;

    @GetMapping
    public List<SessionSummaryDTO> getSessions() {
        return sessionManager.getAllSessionSummaries();
    }
}
