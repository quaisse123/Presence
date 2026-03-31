package com.backend.backend.service;

import java.util.Map;


public interface AuthService {
    public Map<String, String> login(String email, String password);
    public Map<String, String> sendActivationPin(String email);
    public Map<String, String> verifyActivationPin(String email, String pin);
    public Map<String, String> completeActivationProfile(
            String email,
            String firstName,
            String lastName,
            String codeApogee,
            String level,
            String section,
            String major,
            String password
    );
}
