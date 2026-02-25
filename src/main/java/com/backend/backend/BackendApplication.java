package com.backend.backend;

import com.backend.backend.dao.entities.*;
import com.backend.backend.dao.repositories.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.time.LocalDateTime;
import java.util.List;

@SpringBootApplication
public class BackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

	@Bean
	CommandLineRunner seedDatabase(
			UserRepository userRepo,
			CourseRepository courseRepo,
			SessionRepository sessionRepo,
			AttendanceRepository attendanceRepo
	) {
		return args -> {
			// ── Injection unique : on ne fait rien si la DB contient déjà des données ──
			if (userRepo.count() > 0) {
				System.out.println("[DataSeed] Base déjà initialisée, injection ignorée.");
				return;
			}

			System.out.println("[DataSeed] Base vide détectée, injection des données de test...");

			// ── ADMIN ─────────────────────────────────────────────────────────────────
			User admin = new User();
			admin.setEmail("admin@presence.fr");
			admin.setPassword("admin1234");
			admin.setRole(Role.ADMIN);
			admin.setBiometricToken(null);
			userRepo.save(admin);

			// ── PROFESSEURS ───────────────────────────────────────────────────────────
			User prof1 = new User(); prof1.setEmail("dupont.jean@presence.fr");
			prof1.setPassword("prof1234"); prof1.setRole(Role.PROFESSOR);
			prof1.setBiometricToken("bio-prof-001"); userRepo.save(prof1);

			User prof2 = new User(); prof2.setEmail("martin.claire@presence.fr");
			prof2.setPassword("prof1234"); prof2.setRole(Role.PROFESSOR);
			prof2.setBiometricToken("bio-prof-002"); userRepo.save(prof2);

			User prof3 = new User(); prof3.setEmail("leroy.paul@presence.fr");
			prof3.setPassword("prof1234"); prof3.setRole(Role.PROFESSOR);
			prof3.setBiometricToken("bio-prof-003"); userRepo.save(prof3);

			// ── ÉTUDIANTS ─────────────────────────────────────────────────────────────
			String[][] studentData = {
				{"alice.morel@etu.fr",   "bio-stu-001"},
				{"bob.petit@etu.fr",     "bio-stu-002"},
				{"camille.roy@etu.fr",   "bio-stu-003"},
				{"damien.garcia@etu.fr", "bio-stu-004"},
				{"emma.blanc@etu.fr",    "bio-stu-005"},
				{"florian.henry@etu.fr", "bio-stu-006"},
				{"grace.simon@etu.fr",   "bio-stu-007"},
				{"hugo.richard@etu.fr",  "bio-stu-008"},
				{"ines.david@etu.fr",    "bio-stu-009"},
				{"julien.thomas@etu.fr", "bio-stu-010"}
			};
			User[] students = new User[studentData.length];
			for (int i = 0; i < studentData.length; i++) {
				User s = new User();
				s.setEmail(studentData[i][0]);
				s.setPassword("etudiant1234");
				s.setRole(Role.STUDENT);
				s.setBiometricToken(studentData[i][1]);
				students[i] = userRepo.save(s);
			}

			// ── COURS ─────────────────────────────────────────────────────────────────
			Course mathCourse = new Course(); mathCourse.setTitle("Mathématiques Appliquées");
			mathCourse.setCode("MATH-301"); courseRepo.save(mathCourse);

			Course infoCourse = new Course(); infoCourse.setTitle("Informatique Distribuée");
			infoCourse.setCode("INFO-402"); courseRepo.save(infoCourse);

			Course physicsCourse = new Course(); physicsCourse.setTitle("Physique Quantique");
			physicsCourse.setCode("PHYS-201"); courseRepo.save(physicsCourse);

			Course anglaisCourse = new Course(); anglaisCourse.setTitle("Anglais Professionnel");
			anglaisCourse.setCode("ANGL-101"); courseRepo.save(anglaisCourse);

			// ── SESSIONS ──────────────────────────────────────────────────────────────
			// Passées (pour tester les présences)
			Session s1 = new Session();
			s1.setCourse(mathCourse); s1.setProfessor(prof1);
			s1.setStartTime(LocalDateTime.now().minusDays(7).withHour(8).withMinute(0));
			s1.setEndTime(LocalDateTime.now().minusDays(7).withHour(10).withMinute(0));
			s1.setQrCodeToken("QR-MATH-001");
			s1.setLatitude(48.8566); s1.setLongitude(2.3522); s1.setRadiusInMeters(50.0);
			sessionRepo.save(s1);

			Session s2 = new Session();
			s2.setCourse(mathCourse); s2.setProfessor(prof1);
			s2.setStartTime(LocalDateTime.now().minusDays(5).withHour(8).withMinute(0));
			s2.setEndTime(LocalDateTime.now().minusDays(5).withHour(10).withMinute(0));
			s2.setQrCodeToken("QR-MATH-002");
			s2.setLatitude(48.8566); s2.setLongitude(2.3522); s2.setRadiusInMeters(50.0);
			sessionRepo.save(s2);

			Session s3 = new Session();
			s3.setCourse(infoCourse); s3.setProfessor(prof2);
			s3.setStartTime(LocalDateTime.now().minusDays(6).withHour(14).withMinute(0));
			s3.setEndTime(LocalDateTime.now().minusDays(6).withHour(16).withMinute(0));
			s3.setQrCodeToken("QR-INFO-001");
			s3.setLatitude(48.8570); s3.setLongitude(2.3530); s3.setRadiusInMeters(50.0);
			sessionRepo.save(s3);

			Session s4 = new Session();
			s4.setCourse(infoCourse); s4.setProfessor(prof2);
			s4.setStartTime(LocalDateTime.now().minusDays(4).withHour(14).withMinute(0));
			s4.setEndTime(LocalDateTime.now().minusDays(4).withHour(16).withMinute(0));
			s4.setQrCodeToken("QR-INFO-002");
			s4.setLatitude(48.8570); s4.setLongitude(2.3530); s4.setRadiusInMeters(50.0);
			sessionRepo.save(s4);

			Session s5 = new Session();
			s5.setCourse(physicsCourse); s5.setProfessor(prof3);
			s5.setStartTime(LocalDateTime.now().minusDays(3).withHour(10).withMinute(0));
			s5.setEndTime(LocalDateTime.now().minusDays(3).withHour(12).withMinute(0));
			s5.setQrCodeToken("QR-PHYS-001");
			s5.setLatitude(48.8580); s5.setLongitude(2.3540); s5.setRadiusInMeters(50.0);
			sessionRepo.save(s5);

			Session s6 = new Session();
			s6.setCourse(anglaisCourse); s6.setProfessor(prof1);
			s6.setStartTime(LocalDateTime.now().minusDays(2).withHour(16).withMinute(0));
			s6.setEndTime(LocalDateTime.now().minusDays(2).withHour(18).withMinute(0));
			s6.setQrCodeToken("QR-ANGL-001");
			s6.setLatitude(48.8590); s6.setLongitude(2.3550); s6.setRadiusInMeters(50.0);
			sessionRepo.save(s6);

			// Session active (aujourd'hui)
			Session s7 = new Session();
			s7.setCourse(infoCourse); s7.setProfessor(prof2);
			s7.setStartTime(LocalDateTime.now().minusHours(1));
			s7.setEndTime(LocalDateTime.now().plusHours(1));
			s7.setQrCodeToken("QR-INFO-LIVE");
			s7.setLatitude(48.8570); s7.setLongitude(2.3530); s7.setRadiusInMeters(50.0);
			sessionRepo.save(s7);

			// ── PRÉSENCES ─────────────────────────────────────────────────────────────
			// Statuts variés pour simuler la réalité
			AttendanceStatus[] statusPattern = {
				AttendanceStatus.PRESENT, AttendanceStatus.PRESENT, AttendanceStatus.LATE,
				AttendanceStatus.PRESENT, AttendanceStatus.ABSENT, AttendanceStatus.PRESENT,
				AttendanceStatus.PRESENT, AttendanceStatus.LATE,   AttendanceStatus.PRESENT,
				AttendanceStatus.ABSENT
			};

			List<Session> pastSessions = List.of(s1, s2, s3, s4, s5, s6);
			for (Session session : pastSessions) {
				for (int i = 0; i < students.length; i++) {
					AttendanceStatus status = statusPattern[i % statusPattern.length];
					if (status == AttendanceStatus.ABSENT) continue; // Absent = pas d'enregistrement scan

					Attendance a = new Attendance();
					a.setStudent(students[i]);
					a.setSession(session);
					a.setStatus(status);
					a.setScanTime(session.getStartTime().plusMinutes(
						status == AttendanceStatus.LATE ? 20 : 5
					));
					a.setIsOfflineSync(false);
					a.setDeviceId("device-" + studentData[i][1].replace("bio-", ""));
					a.setScanLatitude(session.getLatitude() + (Math.random() * 0.0002 - 0.0001));
					a.setScanLongitude(session.getLongitude() + (Math.random() * 0.0002 - 0.0001));
					attendanceRepo.save(a);
				}
			}

			// Quelques présences sur la session live
			for (int i = 0; i < 5; i++) {
				Attendance a = new Attendance();
				a.setStudent(students[i]);
				a.setSession(s7);
				a.setStatus(AttendanceStatus.PRESENT);
				a.setScanTime(LocalDateTime.now().minusMinutes(45 - i * 5));
				a.setIsOfflineSync(false);
				a.setDeviceId("device-" + studentData[i][1].replace("bio-", ""));
				a.setScanLatitude(s7.getLatitude() + 0.00005);
				a.setScanLongitude(s7.getLongitude() + 0.00005);
				attendanceRepo.save(a);
			}

			System.out.println("[DataSeed] Injection terminée :");
			System.out.println("  - " + userRepo.count() + " utilisateurs (1 admin, 3 profs, 10 étudiants)");
			System.out.println("  - " + courseRepo.count() + " cours");
			System.out.println("  - " + sessionRepo.count() + " sessions (dont 1 en cours)");
			System.out.println("  - " + attendanceRepo.count() + " présences enregistrées");
		};
	}
}
