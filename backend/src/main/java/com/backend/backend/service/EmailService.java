package com.backend.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service // This marks this class as a Spring service bean.
public class EmailService {

    private final JavaMailSender mailSender; // Spring component used to send emails.
    private final String fromEmail; // Sender email address read from application.properties.

    public EmailService(
            JavaMailSender mailSender, // Inject JavaMailSender provided by Spring Boot.
            @Value("${spring.mail.username}") String fromEmail // Inject configured sender address.
    ) {
        this.mailSender = mailSender; // Save the mail sender dependency.
        this.fromEmail = fromEmail; // Save the sender email for outgoing messages.
    }

    public void sendActivationPinEmail(String toEmail, String pin) {
        SimpleMailMessage message = new SimpleMailMessage(); // Create a simple text email object.
        message.setFrom(fromEmail); // Set sender email.
        message.setTo(toEmail); // Set recipient email.
        message.setSubject("Votre code PIN d'activation"); // Set email subject.
        message.setText("Bonjour,\n\nVotre code PIN d'activation est : " + pin
                + "\nCe code expire dans 5 minutes.\n\nEquipe Presence"); // Set email body text.
        mailSender.send(message); // Send email using SMTP configuration.
    }
}
