package com.backend.backend.web;

import com.backend.backend.dto.session.SessionCreateDTO;
import com.backend.backend.dto.session.SessionDTO;
import com.backend.backend.dto.session.SessionResponseDTO;
import com.backend.backend.dto.session.SessionSummaryDTO;
import com.backend.backend.dto.session.StudentSessionHistoryResponseDTO;
import com.backend.backend.service.SessionManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
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

    @PostMapping
    public ResponseEntity<?> createSession(
            @RequestBody SessionCreateDTO body,
            Authentication authentication
    ) {
        try {
            String professorEmail = authentication.getName();
            SessionResponseDTO response = sessionManager.createSessionFromDTO(body, professorEmail);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/{id}/close")
    public ResponseEntity<?> closeSession(@PathVariable Long id) {
        try {
            SessionResponseDTO response = sessionManager.closeSession(id);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteSession(@PathVariable Long id) {
        sessionManager.deleteSession(id);
    }

    @GetMapping("/my-history")
    public ResponseEntity<StudentSessionHistoryResponseDTO> getMySessionHistory(
            Authentication authentication,
            @RequestParam(required = false) String period,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search
    ) {
        String studentEmail = authentication.getName();
        StudentSessionHistoryResponseDTO result =
                sessionManager.getStudentSessionHistory(period, status, search, studentEmail);
        return ResponseEntity.ok(result);
    }
}
