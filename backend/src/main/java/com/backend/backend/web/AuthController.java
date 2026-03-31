package com.backend.backend.web;

import java.util.Map;
import java.util.NoSuchElementException;

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

    @PostMapping("/activation/send-pin")
    public ResponseEntity<Map<String, String>> sendActivationPin(
            @RequestBody Map<String, String> request
    ) {
        try {
            return ResponseEntity.ok(authService.sendActivationPin(request.get("email")));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", e.getMessage())
            );
        }catch (IllegalStateException e) {
            return ResponseEntity.status(409).body(
                    Map.of("error", e.getMessage())
            );
        }
    }

    @PostMapping("/activation/verify-pin")
    public ResponseEntity<Map<String, String>> verifyActivationPin(
            @RequestBody Map<String, String> request
    ) {
        try {
            return ResponseEntity.ok(
                    authService.verifyActivationPin(
                            request.get("email"),
                            request.get("pin")
                    )
            );
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", e.getMessage())
            );
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(404).body(
                    Map.of("error", e.getMessage())
            );
        } catch (IllegalStateException e) {
            return ResponseEntity.status(410).body(
                    Map.of("error", e.getMessage())
            );
        } catch (SecurityException e) {
            return ResponseEntity.status(401).body(
                    Map.of("error", e.getMessage())
            );
        }
    }

    @PostMapping("/activation/complete-profile")
    public ResponseEntity<Map<String, String>> completeActivationProfile(
            @RequestBody Map<String, String> request
    ) {
        try {
            // Accept both frontend names: apogeeCode and codeApogee.
            String apogeeCode = request.get("apogeeCode");
            if (apogeeCode == null || apogeeCode.isBlank()) {
                apogeeCode = request.get("codeApogee");
            }

            return ResponseEntity.ok(
                    authService.completeActivationProfile(
                            request.get("email"),
                            request.get("firstName"),
                            request.get("lastName"),
                            apogeeCode,
                            request.get("level"),
                            request.get("section"),
                            request.get("major"),
                            request.get("password")
                    )
            );
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", e.getMessage())
            );
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(404).body(
                    Map.of("error", e.getMessage())
            );
        } catch (IllegalStateException e) {
            return ResponseEntity.status(412).body(
                    Map.of("error", e.getMessage())
            );
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(
                    Map.of("error", e.getMessage())
            );
        }
    }
}
