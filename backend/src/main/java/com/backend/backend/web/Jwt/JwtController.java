package com.backend.backend.web.Jwt;


import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.http.ResponseEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.backend.backend.service.Jwt.JwtService;

@RestController
@RequestMapping("/api/jwt")
public class JwtController {

    @Autowired
    private JwtService jwtService;

    @Value("${jwt.access.duration}")
    private long jwtAccessDuration;

    @Value("${jwt.refresh.duration}")
    private long jwtRefreshDuration;

    // get token
    @GetMapping("/generate-qr-token")
    public String generateQrToken() {
        // claims Map example 
        Map<String, Object> claims = Map.of(
            "userId", 123,
            "username", "john_doe",
            "roles", new String[]{"USER", "ADMIN"}
        );
        // expiration time example: 1 hour (3600000 ms)
        String token = jwtService.generateToken(claims, 3600000 , "prof.email@gmail.com"); // 1 hour validity
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
