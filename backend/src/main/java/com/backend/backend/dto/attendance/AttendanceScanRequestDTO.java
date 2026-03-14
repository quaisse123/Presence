package com.backend.backend.dto.attendance;

import lombok.Data;
import java.time.LocalDateTime;

/**
 * DTO for attendance scan request (QR scan by student).
 * Used by POST /api/attendance/scan.
 */
@Data
public class AttendanceScanRequestDTO {
    /** QR code token from scanned session */
    private String qrCodeToken;
    /** Student unique ID */
    private Long studentId;
    /** Latitude at scan time */
    private Double scanLatitude;
    /** Longitude at scan time */
    private Double scanLongitude;
    /** Device identifier (phone, etc.) */
    private String deviceId;
    /** Scan timestamp (client clock) */
    private LocalDateTime scanTime;
}
