package com.backend.backend.service.Jwt;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;



@Service
public class JwtService {
    @Value("${jwtSecretKey}")
    private String mySecretKey;
    
    
	// Génère un JWT avec des claims personnalisés et une durée de validité
	public String generateToken(Map<String, Object> claims, long durationMillis) {

		// Date de génération du token (maintenant)
		Date now = new Date();

		// Date d'expiration du token (maintenant + durée en ms)
		Date expiryDate = new Date(now.getTime() + durationMillis);

		// Construction du token JWT
		String token = Jwts.builder()
				// Ajoute les claims personnalisés (payload)
				.setClaims(claims)
				// Définit la date d'émission
				.setIssuedAt(now)
				// Définit la date d'expiration
				.setExpiration(expiryDate)
				// Signe le token avec la clé secrète et l'algorithme HS256
				.signWith(Keys.hmacShaKeyFor(mySecretKey.getBytes()), SignatureAlgorithm.HS256)
				// Génère la chaîne JWT finale
				.compact();

		// Retourne le token généré
		return token;
	}

	// Valide le token JWT (signature, expiration, etc.)

	// Valide le token JWT (signature, expiration, etc.)
	public boolean validateToken(String token) {
		try {
			// Parse le token et vérifie la signature et l'expiration
			Jwts.parserBuilder()
				.setSigningKey(Keys.hmacShaKeyFor(mySecretKey.getBytes()))
				.build()
				.parseClaimsJws(token);
			// Si aucune exception, le token est valide
			return true;
		} catch (io.jsonwebtoken.JwtException | IllegalArgumentException e) {
			// Token invalide ou expiré
			return false;
		}
	}

	// Extrait les claims du token JWT
	public Map<String, Object> extractClaims(String token) {
		// Parse le token et récupère les claims
    Claims claims = Jwts.parserBuilder()
			.setSigningKey(Keys.hmacShaKeyFor(mySecretKey.getBytes()))
			.build()
			.parseClaimsJws(token)
			.getBody();
		// Retourne les claims sous forme de Map
		return new HashMap<>(claims);
	}
}
