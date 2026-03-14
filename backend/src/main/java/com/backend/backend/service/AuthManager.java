package com.backend.backend.service;


import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
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


    @Override
    public Map<String, String> login(String email, String password) {
        User user = userRepository.findByEmail(email) ;
        if (user == null) {
            throw new RuntimeException("Incorrect email or password");
        }

        if (!user.getPassword().equals(password)) {
            throw new RuntimeException("Incorrect email or password");
        }

        Map<String, Object> claims = new HashMap<>();
        claims.put("role", user.getRole().name());
        claims.put("userId", user.getId());
        if (user.getGroup() != null) {
            claims.put("groupId", user.getGroup().getId());
        }

        // // Duration 15 min
        // final long JWT_ACCESS_DURATION = 15 * 60 * 1000;
        // // Duration 7 days
        // final long JWT_REFRESH_DURATION = 7 * 24 * 60 * 60 * 1000;

        // 1 min acess
        final long JWT_ACCESS_DURATION = 1 * 60 * 1000;
        // 5 min refresh  
        final long JWT_REFRESH_DURATION = 2 * 60 * 1000;

        String accessToken = jwtService.generateToken(claims, JWT_ACCESS_DURATION , user.getEmail());
        String refreshToken = jwtService.generateToken(claims, JWT_REFRESH_DURATION , user.getEmail());

        Map<String, String> tokens = new HashMap<>();
        tokens.put("accessToken", accessToken);
        tokens.put("refreshToken", refreshToken);

        // Implement login logic here
        return tokens;
    }
    
}
