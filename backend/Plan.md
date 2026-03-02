# Plan: Presence App — Prof & Student Sides

## Overview
Build Professor and Student feature pages with fully open REST endpoints (no auth yet).
Both sides work independently. Auth + role enforcement (JWT + email-suffix routing) is added
at the end as a contained refactor. Enrollment is skipped for MVP — students see all courses/sessions globally.

---

## Missing Piece — Add First
- Implement `SessionManager.createSession()` to auto-generate `qrCodeToken` as `UUID.randomUUID().toString()`

---

## Professor Side

### US-P1 — Course Management
**Page:** `/professor/courses`
- View all courses, create new, delete
- `GET /api/courses`
- `POST /api/courses` (CourseCreateDTO: title, code)
- `DELETE /api/courses/{id}`

### US-P2 — Create / Launch a Session
**Page:** `/professor/sessions/new`
- Fill course, GPS coords, duration → submit → session created with auto-generated QR token
- `GET /api/sessions`
- `POST /api/sessions` (SessionCreateDTO: startTime, endTime, latitude, longitude, radiusInMeters, courseId, professorId)
- `DELETE /api/sessions/{id}`

### US-P3 — Active Session / QR Display
**Page:** `/professor/sessions/{id}/live`
- Shows QR code (render qrCodeToken as QR image in Flutter), session countdown timer, close button
- `GET /api/sessions/{id}`
- `PUT /api/sessions/{id}/close` → sets endTime to now

### US-P4 — Attendance Sheet
**Page:** `/professor/sessions/{id}/attendance`
- List all attendance records: student, scanTime, status, GPS
- `GET /api/sessions/{id}/attendances`
- Requires: `AttendanceRepository.findBySession_Id(Long sessionId)`

---

## Student Side

### US-S1 — Browse Courses & Sessions
**Page:** `/student/courses`
- All courses; tap → sessions list for that course
- `GET /api/courses`
- `GET /api/courses/{id}/sessions`
- Requires: `SessionRepository.findByCourse_Id(Long courseId)`

### US-S2 — Scan QR Code
**Page:** `/student/scan`
- Flutter camera scans QR → extracts qrCodeToken → hits backend
- `POST /api/attendance/scan`
  - Body: `{ qrCodeToken, studentId, scanLatitude, scanLongitude, deviceId, scanTime }`
  - Logic:
    1. Find session by qrCodeToken (`SessionRepository.findByQrCodeToken()`)
    2. Check session is active (now between startTime and endTime)
    3. Check GPS distance ≤ radiusInMeters (Haversine formula)
    4. Compute status: on time → PRESENT, within grace period → LATE, else → reject
    5. Save attendance, return AttendanceResponseDTO
- `POST /api/attendance/sync` (offline batch — list of AttendanceCreateDTO, same logic using stored scanTime)

### US-S3 — Attendance History
**Page:** `/student/attendance`
- All attendance records for a student: session info, status breakdown per course
- `GET /api/students/{studentId}/attendances`
  - Requires: `AttendanceRepository.findByStudent_Id(Long studentId)`
- `GET /api/students/{studentId}/summary`
  - Aggregate present/late/absent counts per course (computed in service layer)

---

## Implementation Steps

1. Implement `SessionManager.createSession()` — generate UUID for qrCodeToken
2. Add custom repo queries:
   - `SessionRepository.findByQrCodeToken(String token)`
   - `SessionRepository.findByCourse_Id(Long courseId)`
   - `AttendanceRepository.findBySession_Id(Long sessionId)`
   - `AttendanceRepository.findByStudent_Id(Long studentId)`
3. Implement all `*Manager` CRUD methods (Course, Session, User, Attendance)
4. Add controllers: `CourseController`, `SessionController`, `UserController`, `AttendanceController`
5. Add `POST /api/attendance/scan` — session validation + Haversine GPS check + status logic
6. Add `POST /api/attendance/sync` — offline batch sync
7. Flutter: Professor pages (Courses list → Create session → Live QR → Attendance sheet)
8. Flutter: Student pages (Browse courses/sessions → Scan QR → History)
9. *(Later)* Spring Security + JWT — replace hardcoded IDs with `@AuthenticationPrincipal`
   - Email-suffix routing: `@ensam-casa.com` → STUDENT, `@ensam.com` → PROFESSOR

---

## Decisions
- Enrollment skipped: student side shows all courses/sessions globally for now
- qrCodeToken = `UUID.randomUUID().toString()` (auto-generated, not in SessionCreateDTO)
- LATE threshold: TBD — confirm grace period in minutes after startTime
- Offline sync trusts client-supplied scanTime for now (security hardening deferred)
- Auth left last: StudentId/professorId passed explicitly in requests during dev; swapped to JWT principal later

## Verification
- Create course → create session → verify qrCodeToken auto-generated
- POST scan with valid coords + active session → expect PRESENT
- POST scan outside GPS radius → expect rejection
- POST scan after endTime → expect rejection
- Use H2 console (`/h2-console`) to inspect raw data