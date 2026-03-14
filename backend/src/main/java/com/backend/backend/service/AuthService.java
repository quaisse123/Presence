package com.backend.backend.service;

import java.util.Map;


public interface AuthService {
    public Map<String, String> login(String email, String password);
}
