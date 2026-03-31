package com.backend.backend.service;


import java.security.SecureRandom;
import java.time.Instant;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.regex.Pattern;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.backend.backend.dao.entities.ActivationPin;
import com.backend.backend.dao.entities.Group;
import com.backend.backend.dao.entities.Role;
import com.backend.backend.dao.entities.Status;
import com.backend.backend.dao.entities.User;
import com.backend.backend.dao.repositories.ActivationPinRepository;
import com.backend.backend.dao.repositories.GroupRepository;
import com.backend.backend.dao.repositories.UserRepository;
import com.backend.backend.service.Jwt.JwtService;

import jakarta.transaction.Transactional;

@Service
public class AuthManager implements AuthService {

    private static final Pattern ENSAM_EMAIL_PATTERN = Pattern.compile(
            "^[a-z0-9._%+-]+@ensam-casa\\.ma$"
    );
    private static final long PIN_MAX_AGE_SECONDS = 5 * 60;

    private final SecureRandom secureRandom = new SecureRandom();

    @Autowired
    private UserRepository userRepository; 

    @Autowired
    private ActivationPinRepository activationPinRepository;

    @Autowired
    private GroupRepository groupRepository;

    @Autowired
    private ActivationMembershipHelper activationMembershipHelper;

    @Autowired
    private JwtService jwtService ;

    @Autowired
    private EmailService emailService; // Service responsible for sending the PIN by email.

    @Autowired
    private PasswordService passwordService;

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

        if (!isPasswordValid(password, user.getPassword())) {
            throw new RuntimeException("Incorrect email or password");
        }

        if (!user.getEmail().endsWith("@ensam-casa.ma")) {
            throw new RuntimeException("Email must end with '@ensam-casa.ma'");
        }

        // Block login until account activation is completed.
        if (Status.INACTIVE.equals(user.getStatus())) {
            throw new RuntimeException("Account inactive. Complete activation first.");
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

    @Override
    public Map<String, String> sendActivationPin(String rawEmail) {
        String email = normalizeEmail(rawEmail); // Normalize input email for consistent checks.

        if (email == null || !ENSAM_EMAIL_PATTERN.matcher(email).matches()) {
            throw new IllegalArgumentException(
                    "Use a valid institutional email ending with @ensam-casa.ma"
            );
        }

        // User user = userRepository.findByEmail(email);
        // if (user.getStatus() != Status.INACTIVE) {
        //     throw new IllegalStateException("Account is already active. No PIN needed.");
        // }

        String pin = String.format("%04d", secureRandom.nextInt(10000)); // Generate a random 4-digit PIN.

        // Persist PIN state so activation survives backend restarts and multi-instance deployments.
        ActivationPin activationPin = activationPinRepository.findByEmail(email)
                .orElseGet(ActivationPin::new);
        activationPin.setEmail(email);
        activationPin.setPin(pin);
        activationPin.setPinCreatedAt(Instant.now());
        activationPin.setPinVerifiedAt(null); // Reset verification marker when issuing a fresh PIN.
        activationPinRepository.save(activationPin);

        emailService.sendActivationPinEmail(email, pin); // Send the generated PIN to user email.

        Map<String, String> response = new HashMap<>(); // Build API response map.
        response.put("message", "PIN generated and sent by email successfully"); // Inform client of success.
        response.put("email", email); // Return normalized email for UI confirmation.
        return response;
    }

    @Override
    public Map<String, String> verifyActivationPin(String rawEmail, String pin) {
        String email = normalizeEmail(rawEmail);

        if (email == null || pin == null || pin.isBlank()) {
            throw new IllegalArgumentException("Email and PIN are required");
        }

        // Read latest activation state from database instead of volatile memory.
        ActivationPin activationPin = activationPinRepository.findByEmail(email)
                .orElseThrow(() -> new NoSuchElementException("No PIN found for this email. Please request a new one."));

        if (activationPin.getPin() == null || activationPin.getPinCreatedAt() == null) {
            throw new NoSuchElementException("No PIN found for this email. Please request a new one.");
        }

        if (isExpired(activationPin.getPinCreatedAt())) {
            // Expired records are cleaned immediately to avoid stale verification attempts.
            activationPinRepository.deleteByEmail(email);
            throw new IllegalStateException("PIN expired. Please request a new one.");
        }

        if (!activationPin.getPin().equals(pin.trim())) {
            throw new SecurityException("Invalid PIN code");
        }

        // Consume the PIN and persist a verification marker for the profile completion step.
        activationPin.setPin(null);
        activationPin.setPinCreatedAt(null);
        activationPin.setPinVerifiedAt(Instant.now());
        activationPinRepository.save(activationPin);

        Map<String, String> response = new HashMap<>();
        response.put("message", "PIN verified successfully");
        return response;
    }

    @Transactional
    @Override
    public Map<String, String> completeActivationProfile(
            String rawEmail,
            String rawFirstName,
            String rawLastName,
            String rawCodeApogee,
            String rawLevel,
            String rawSection,
            String rawMajor,
            String rawPassword
    ) {
        // Step 1: normalize and validate required fields from frontend payload.
        String email = normalizeEmail(rawEmail);
        String firstName = normalizeText(rawFirstName);
        String lastName = normalizeText(rawLastName);
        String codeApogee = normalizeText(rawCodeApogee);
        String normalizedLevel = normalizeLevel(rawLevel);
        String normalizedSection = normalizeUpper(rawSection);
        String normalizedMajor = normalizeUpper(rawMajor);
        String password = normalizeText(rawPassword);

        if (email == null || firstName == null || lastName == null || codeApogee == null || normalizedLevel == null) {
            throw new IllegalArgumentException("Email, firstName, lastName, codeApogee and level are required");
        }

        if (!Pattern.matches("^\\d{8}$", codeApogee)) {
            throw new IllegalArgumentException("Apogee code must contain exactly 8 digits");
        }

        if (password == null || password.length() < 8) {
            throw new IllegalArgumentException("Password must contain at least 8 characters");
        }

        // Step 2: enforce activation flow order (PIN verification marker must exist in DB).
        ActivationPin activationPin = activationPinRepository.findByEmail(email)
                .orElse(null);
        if (activationPin == null || activationPin.getPinVerifiedAt() == null) {
            throw new IllegalStateException("PIN verification is required before completing activation");
        }

        // Step 3: load student account and check apogee uniqueness.
        User user = userRepository.findByEmail(email);
        if (user == null) {
            throw new NoSuchElementException("No user account found for this email");
        }

        if (user.getRole() != Role.STUDENT) {
            throw new IllegalArgumentException("Activation profile is only available for student accounts");
        }

        User existingApogee = userRepository.findByCodeApogee(codeApogee);
        if (existingApogee != null && !existingApogee.getId().equals(user.getId())) {
            throw new IllegalStateException("Apogee code already used by another account");
        }

        // Step 4: resolve selected group from level/section/major.
        Group selectedGroup = resolveSelectedGroup(normalizedLevel, normalizedSection, normalizedMajor);

        // Step 5: TODO helper for enrollment check (currently always true).
        boolean belongsToGroup = activationMembershipHelper.belongsToSelectedGroup(email, codeApogee, selectedGroup);
        if (!belongsToGroup) {
            throw new SecurityException("Vous ne faites pas partie de la filiere/groupe choisi");
        }

        // Step 6: persist profile data and activate account.
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setCodeApogee(codeApogee);
        user.setGroup(selectedGroup);
        user.setPassword(passwordService.hashPassword(password));
        user.setStatus(Status.ACTIVE);
        userRepository.save(user);

        // Step 7: consume persisted activation marker after successful profile completion.
        activationPinRepository.deleteByEmail(email);

        Map<String, String> response = new HashMap<>();
        response.put("message", "Activation completed successfully, you can now log in");
        response.put("status", user.getStatus().name());
        response.put("groupId", String.valueOf(selectedGroup.getId()));
        return response;
    }

    private String normalizeEmail(String email) {
        if (email == null) {
            return null;
        }
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizeText(String text) {
        if (text == null) {
            return null;
        }
        String normalized = text.trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private String normalizeUpper(String text) {
        String normalized = normalizeText(text);
        return normalized == null ? null : normalized.toUpperCase(Locale.ROOT);
    }

    private String normalizeLevel(String level) {
        String normalized = normalizeUpper(level);
        if (normalized == null) {
            return null;
        }

        // Frontend currently sends API-I / CI-II format, while groups are stored as API-1 / CI-2.
        return switch (normalized) {
            case "API-I" -> "API-1";
            case "API-II" -> "API-2";
            case "CI-I" -> "CI-1";
            case "CI-II" -> "CI-2";
            case "CI-III" -> "CI-3";
            default -> normalized;
        };
    }

    private Group resolveSelectedGroup(String level, String section, String major) {
        // API flow: level + section must identify one group.
        if ("API-1".equals(level) || "API-2".equals(level)) {
            if (section == null) {
                throw new IllegalArgumentException("Section is required for API level");
            }

            return groupRepository.findByLevel(level).stream()
                    .filter(group -> group.getSection() != null)
                    .filter(group -> section.equalsIgnoreCase(group.getSection()))
                    .findFirst()
                    .orElseThrow(() -> new NoSuchElementException("Selected API group not found"));
        }

        // CI flow: level + major(filiere) must identify one group.
        if ("CI-1".equals(level) || "CI-2".equals(level) || "CI-3".equals(level)) {
            if (major == null) {
                throw new IllegalArgumentException("Major is required for CI level");
            }

            return groupRepository.findByFiliereAndLevel(major, level).stream()
                    .findFirst()
                    .orElseThrow(() -> new NoSuchElementException("Selected CI group not found"));
        }

        throw new IllegalArgumentException("Unsupported level value");
    }

    private boolean isExpired(Instant pinCreatedAt) {
        return pinCreatedAt.plusSeconds(PIN_MAX_AGE_SECONDS).isBefore(Instant.now());
    }

    private boolean isPasswordValid(String rawPassword, String storedPassword) {
        if (rawPassword == null || storedPassword == null) {
            return false;
        }

        // Keep compatibility with old seeded plain-text passwords.
        if (storedPassword.startsWith("$2a$") || storedPassword.startsWith("$2b$") || storedPassword.startsWith("$2y$")) {
            return passwordService.matches(rawPassword, storedPassword);
        }

        return storedPassword.equals(rawPassword);
    }
    
}
