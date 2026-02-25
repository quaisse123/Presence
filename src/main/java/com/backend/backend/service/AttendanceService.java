package com.backend.backend.service;

import com.backend.backend.dao.entities.Attendance;
import java.util.List;

public interface AttendanceService {

    Attendance createAttendance(Attendance attendance);

    Attendance getAttendanceById(Long id);

    List<Attendance> getAllAttendances();

    Attendance updateAttendance(Long id, Attendance attendance);

    void deleteAttendance(Long id);
}
