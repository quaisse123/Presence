package com.backend.backend.web.Jwt;

import java.util.Map;

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

    // get token
    @GetMapping("/generate-qr-token")
    public String generateQrToken() {
        // claims Map example 
        Map<String, Object> claims = Map.of(
            "userId", 123,
            "username", "john_doe",
            "roles", new String[]{"USER", "ADMIN"}
        );
        String token = jwtService.generateToken(claims, 3600000); // 1 hour validity
        return token;
    }
}   
