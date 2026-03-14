package com.backend.backend.service.Jwt;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;



@Service
public class JwtService {
    @Value("${jwtSecretKey}")
    private String mySecretKey;
    
    
	// Génère un JWT avec des claims personnalisés et une durée de validité
	public String generateToken(Map<String, Object> claims, long durationMillis , String subject) {

		// Date de génération du token (maintenant)
		Date now = new Date();

		// Date d'expiration du token (maintenant + durée en ms)
		Date expiryDate = new Date(now.getTime() + durationMillis);

		// Construction du token JWT
		String token = Jwts.builder()
				// setClaims DOIT être appelé AVANT setSubject
				// car setClaims() écrase tous les claims précédents (y compris sub)
				.setClaims(claims)
				// Définit le subject (email) APRÈS setClaims pour qu'il soit conservé
				.setSubject(subject)
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

		// Rafraîchit les tokens à partir d'un refresh token valide
	public Map<String, String> refreshTokens(String refreshToken, long accessDuration, long refreshDuration) {
		if (!validateToken(refreshToken)) {
			throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Expired or invalid refresh token");
		}
		Map<String, Object> claims = extractClaims(refreshToken);
		String subject = (String) claims.get("sub");
		if (subject == null && claims.containsKey("email")) {
			subject = (String) claims.get("email");
		}
		if (subject == null) {
			throw new RuntimeException("Impossible de déterminer le sujet du token");
		}
		// On retire les claims standards pour éviter les conflits
		claims.remove("sub");
		claims.remove("iat");
		claims.remove("exp");
		String newAccessToken = generateToken(claims, accessDuration, subject);
		String newRefreshToken = generateToken(claims, refreshDuration, subject);
		Map<String, String> tokens = new HashMap<>();
		tokens.put("accessToken", newAccessToken);
		tokens.put("refreshToken", newRefreshToken);
		return tokens;
	}
}
