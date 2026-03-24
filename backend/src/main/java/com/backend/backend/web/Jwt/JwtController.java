package com.backend.backend.web.Jwt;


import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.http.ResponseEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.backend.backend.dao.entities.Session;
import com.backend.backend.dao.repositories.SessionRepository;
import com.backend.backend.service.Jwt.JwtService;

@RestController
@RequestMapping("/api/jwt")
public class JwtController {

    @Autowired
    private JwtService jwtService;

    @Autowired
    private SessionRepository sessionRepository;

    @Value("${jwt.access.duration}")
    private long jwtAccessDuration;

    @Value("${jwt.refresh.duration}")
    private long jwtRefreshDuration;

    @Value("${jwt.qr.duration}")
    private long jwtQrDuration;

    // Generate a short-lived QR token bound to one session.
    @GetMapping("/generate-qr-token")
    public String generateQrToken(@RequestParam Long sessionId) {
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session introuvable."));

        Map<String, Object> claims = Map.of(
                "type", "attendance_qr",
                "sessionId", session.getId()
        );

        String token = jwtService.generateToken(claims, jwtQrDuration, "session:" + session.getId());
        return token;
    }

    // Endpoint pour rafraîchir les tokens
    @PostMapping("/refresh")
    public ResponseEntity<Map<String, String>> refreshTokens(@RequestBody Map<String, String> body) {
        String refreshToken = body.get("refreshToken");
        Map<String, String> tokens = jwtService.refreshTokens(refreshToken, jwtAccessDuration, jwtRefreshDuration);
        return ResponseEntity.ok(tokens);
    }

    // Endpoint pour vérifier la validité d'un token
    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        return ResponseEntity.ok("Token is valid!");
    }
}   
