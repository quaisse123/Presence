package com.backend.backend.web;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.backend.backend.service.AuthService;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    
    @Autowired
    private AuthService authService ;

    @PostMapping("/login")
    public ResponseEntity<Map<String,String>> login(@RequestBody Map<String, String> credentials ) {
        String email = credentials.get("email");
        String password = credentials.get("password");
        
        Map<String, String> tokens;
        try {
            // Implement login logic here
            tokens  = authService.login(email, password);
        } catch (Exception e) {
            return ResponseEntity.status(401).body(Map.of("error", e.getMessage()));
        }
        return ResponseEntity.ok(tokens); 
    }
}
