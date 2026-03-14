package com.backend.backend.config;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import java.util.Collections;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import com.backend.backend.service.Jwt.JwtService;
import io.jsonwebtoken.JwtException;
import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    // Service pour valider et extraire les infos du JWT
    @Autowired
    private JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        // Récupère l'en-tête Authorization
        String authHeader = request.getHeader("Authorization");

        // Vérifie que l'en-tête existe et commence par "Bearer "
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            // Extrait le token JWT (après "Bearer ")
            String jwt = authHeader.substring(7);
            try {
                // Valide le token (signature, expiration, etc.)
                if (jwtService.validateToken(jwt)) {
                    
                    // On extrait les claims du token (payload)
                    var claims = jwtService.extractClaims(jwt);
                    // On récupère l'email (subject) et le rôle depuis les claims
                    String email = (String) claims.getOrDefault("sub", null);
                    String role = (String) claims.getOrDefault("role", null);
                    // Si l'utilisateur n'est pas déjà authentifié dans le contexte
                    if (email != null && role != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                        // On crée une autorité Spring à partir du rôle (ex: ROLE_ADMIN)
                        var authorities = Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role));
                        // On crée un objet Authentication avec l'email et le rôle
                        var auth = new UsernamePasswordAuthenticationToken(email, null, authorities);
                        // On place l'objet Authentication dans le contexte de sécurité
                        SecurityContextHolder.getContext().setAuthentication(auth);
                        // À partir de là, Spring Security considère la requête comme authentifiée
                    }
                }
            } catch (JwtException e) {
                // Si le token est invalide, retourne 401 Unauthorized
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().write("Invalid or expired JWT token");
                return;
            }
        }
        // Passe la requête au filtre suivant (ou au contrôleur)
        filterChain.doFilter(request, response);
    }
}
