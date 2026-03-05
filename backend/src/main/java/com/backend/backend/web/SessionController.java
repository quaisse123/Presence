package com.backend.backend.web;

import com.backend.backend.dto.session.SessionDTO;
import com.backend.backend.dto.session.SessionSummaryDTO;
import com.backend.backend.service.SessionManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/api/sessions")
public class SessionController {

    @Autowired
    private SessionManager sessionManager;

    @GetMapping
    public Page<SessionSummaryDTO> getSessions(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10" ) int size
    ) {
        return sessionManager.getAllSessionSummaries(page, size);
    }

    @GetMapping("/{id}")
    public SessionDTO getSessionDetail(@PathVariable Long id) {
        return sessionManager.getSessionDetail(id);
    }
}
