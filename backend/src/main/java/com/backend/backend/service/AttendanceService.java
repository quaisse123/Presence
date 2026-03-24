package com.backend.backend.service;

import com.backend.backend.dao.entities.Attendance;
import com.backend.backend.dto.attendance.AttendanceMyResponseDTO;
import com.backend.backend.dto.attendance.AttendanceResponseDTO;
import com.backend.backend.dto.attendance.AttendanceScanRequestDTO;
import com.backend.backend.dto.attendance.AttendanceSummaryDTO;

import java.util.List;

public interface AttendanceService {

    Attendance createAttendance(Attendance attendance);

    Attendance getAttendanceById(Long id);

    List<Attendance> getAllAttendances();

    Attendance updateAttendance(Long id, Attendance attendance);

    void deleteAttendance(Long id);

    AttendanceResponseDTO scanAttendance(AttendanceScanRequestDTO request);

    AttendanceMyResponseDTO getStudentAttendances(String period, String status, String search, String studentEmail);
}
