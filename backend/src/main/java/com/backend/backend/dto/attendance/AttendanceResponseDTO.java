package com.backend.backend.dto.attendance;

import com.backend.backend.dao.entities.AttendanceStatus;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AttendanceResponseDTO {
    private Long id;
    private LocalDateTime scanTime;
    private AttendanceStatus status;
    private Boolean isOfflineSync;
    private String deviceId;
    private Double scanLatitude;
    private Double scanLongitude;
    private Long studentId;
    private Long sessionId;

    private Boolean success; // Indique si la validation de présence a réussi
    private String message; // Message d'erreur ou de succès pour le client
}
