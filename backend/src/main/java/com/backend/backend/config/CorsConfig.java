package com.backend.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {

    /**
     * Origines autorisées, séparées par des virgules.
     * Surchargé par la variable d'environnement CORS_ALLOWED_ORIGINS.
     * Vide par défaut → aucune restriction CORS (adapté à une app mobile,
     * qui n'est pas soumise au CORS navigateur).
     */
    @Value("${cors.allowed-origins:}")
    private String allowedOrigins;

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                List<String> origins = parseOrigins(allowedOrigins);

                var mapping = registry.addMapping("/**")
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*");

                // Si des origines sont configurées, on les applique.
                // Sinon, on laisse le CORS ouvert (dev / app mobile).
                if (!origins.isEmpty()) {
                    mapping.allowedOrigins(origins.toArray(new String[0]));
                }
            }
        };
    }

    private List<String> parseOrigins(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return List.of();
        }
        return Arrays.stream(raw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
    }
}