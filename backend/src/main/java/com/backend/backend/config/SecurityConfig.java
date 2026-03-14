package com.backend.backend.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
public class SecurityConfig {

    @Autowired
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // Désactive CSRF car on est en stateless (API REST)
                .csrf(csrf -> csrf
                        .ignoringRequestMatchers("/h2-console/**") // Désactive CSRF pour H2
                        .disable())
                .headers(headers -> headers
                        .frameOptions(frame -> frame.disable()) // Autorise l'affichage en iframe pour H2
                )
                // On définit les règles d'autorisation
                .authorizeHttpRequests(auth -> auth
                        // Autorise librement les endpoints d'authentification et de refresh
                        .requestMatchers(
                                "/api/auth/**",
                                "/api/jwt/refresh",
                                "/api/jwt/generate-qr-token",
                                "/api/attendance/scan",
                                "/h2-console/**" // Si vous utilisez la console H2 pour le développement
                        ).permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/sessions/*").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/attendance/scan").permitAll()
                        // Toutes les autres requêtes nécessitent un JWT valide
                        .anyRequest().authenticated())
                // On précise que la session est stateless (pas de session côté serveur)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // Retourne 401 (pas 403) pour les requêtes non authentifiées
                // .exceptionHandling(ex -> ex
                //         .authenticationEntryPoint((request, response, authException) -> {
                //             response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                //             response.setContentType("application/json");
                //             response.getWriter().write("{\"error\": \"Unauthorized: token missing or expired\"}");
                //         }))
                // Ajoute notre filtre JWT AVANT le filtre d'authentification standard
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
