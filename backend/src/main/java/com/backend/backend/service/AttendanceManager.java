package com.backend.backend.service;

import com.backend.backend.dao.entities.Attendance;
import com.backend.backend.dao.repositories.AttendanceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class AttendanceManager implements AttendanceService {

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Override
    public Attendance createAttendance(Attendance attendance) {
        return null;
    }

    @Override
    public Attendance getAttendanceById(Long id) {
        return null;
    }

    @Override
    public List<Attendance> getAllAttendances() {
        return null;
    }

    @Override
    public Attendance updateAttendance(Long id, Attendance attendance) {
        return null;
    }

    @Override
    public void deleteAttendance(Long id) {

    }
}
