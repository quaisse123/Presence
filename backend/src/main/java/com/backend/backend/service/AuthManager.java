package com.backend.backend.service;


import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.backend.backend.dao.entities.User;
import com.backend.backend.dao.repositories.UserRepository;
import com.backend.backend.service.Jwt.JwtService;

@Service
public class AuthManager implements AuthService {

    @Autowired
    private UserRepository userRepository; 

    @Autowired
    private JwtService jwtService ;

    @Value("${jwt.access.duration}")
    private long jwtAccessDuration;

    @Value("${jwt.refresh.duration}")
    private long jwtRefreshDuration;


    @Override
    public Map<String, String> login(String email, String password) {
        User user = userRepository.findByEmail(email) ;
        if (user == null) {
            throw new RuntimeException("Incorrect email or password");
        }

        if (!user.getPassword().equals(password)) {
            throw new RuntimeException("Incorrect email or password");
        }

        if (!user.getEmail().endsWith("@ensam-casa.ma")) {
            throw new RuntimeException("Email must end with @ensam-casa.ma");
        }

        Map<String, Object> claims = new HashMap<>();
        claims.put("role", user.getRole().name());
        claims.put("userId", user.getId());
        if (user.getGroup() != null) {
            claims.put("groupId", user.getGroup().getId());
        }

        String accessToken = jwtService.generateToken(claims, jwtAccessDuration, user.getEmail());
        String refreshToken = jwtService.generateToken(claims, jwtRefreshDuration, user.getEmail());

        Map<String, String> tokens = new HashMap<>();
        tokens.put("accessToken", accessToken);
        tokens.put("refreshToken", refreshToken);

        // Implement login logic here
        return tokens;
    }
    
}
