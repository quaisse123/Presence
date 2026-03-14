package com.backend.backend.web;

import com.backend.backend.dto.attendance.AttendanceScanRequestDTO;
import com.backend.backend.dto.attendance.AttendanceResponseDTO;
import com.backend.backend.service.AttendanceManager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    @Autowired
    private AttendanceManager attendanceManager;

    @PostMapping("/scan")
    public ResponseEntity<AttendanceResponseDTO> scanAttendance(@RequestBody AttendanceScanRequestDTO request) {
        AttendanceResponseDTO response = attendanceManager.scanAttendance(request);
        if (response.getSuccess()) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.badRequest().body(response);
        }
    }
}
