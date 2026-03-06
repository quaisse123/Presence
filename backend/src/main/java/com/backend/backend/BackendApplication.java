package com.backend.backend;

import com.backend.backend.dao.entities.*;
import com.backend.backend.dao.repositories.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

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
			AttendanceRepository attendanceRepo,
			GroupRepository groupRepo
	) {
		return args -> {
			if (userRepo.count() > 0) {
				System.out.println("[DataSeed] Base déjà initialisée, injection ignorée.");
				return;
			}

			System.out.println("[DataSeed] Base vide — injection en cours...");

			Random rand = new Random(42); // seed fixe → résultats reproductibles

			// ══════════════════════════════════════════════════════════
			//  GROUPES
			//  CI  : level="CI-1/2/3", section=null,  filiere="IAGI"|"GSI"|...
			//  API : level="API-1/2",  section="A".."E", filiere=null
			// ══════════════════════════════════════════════════════════
			// {level, section, filiere, nbStudents}
			Object[][] groupDefs = {
				{"API-1", "A", null,    55},
				{"API-1", "B", null,    53},
				{"API-1", "C", null,    57},
				{"API-1", "D", null,    52},
				{"API-1", "E", null,    56},
				{"API-2", "A", null,    58},
				{"API-2", "B", null,    51},
				{"API-2", "C", null,    54},
				{"CI-1",  null, "IAGI", 60},
				{"CI-2",  null, "GSI",  50},
			};

			Group[] groups = new Group[groupDefs.length];
			for (int i = 0; i < groupDefs.length; i++) {
				Group g = new Group();
				g.setLevel((String) groupDefs[i][0]);
				g.setSection((String) groupDefs[i][1]);
				g.setFiliere((String) groupDefs[i][2]);
				g.setTotalStudents(0);
				groups[i] = groupRepo.save(g);
			}

			// ══════════════════════════════════════════════════════════
			//  ADMIN
			// ══════════════════════════════════════════════════════════
			User admin = new User();
			admin.setEmail("admin@presence.fr");
			admin.setPassword("admin1234");
			admin.setRole(Role.ADMIN);
			userRepo.save(admin);

			// ══════════════════════════════════════════════════════════
			//  PROFESSEURS
			// ══════════════════════════════════════════════════════════
			String[][] profDefs = {
				{"dupont.jean@presence.fr",   "bio-prof-001"},
				{"martin.claire@presence.fr", "bio-prof-002"},
				{"leroy.paul@presence.fr",    "bio-prof-003"},
				{"benali.sara@presence.fr",   "bio-prof-004"},
				{"roux.marc@presence.fr",     "bio-prof-005"},
				{"faure.camille@presence.fr", "bio-prof-006"},
			};
			User[] profs = new User[profDefs.length];
			for (int i = 0; i < profDefs.length; i++) {
				User p = new User();
				p.setEmail(profDefs[i][0]);
				p.setPassword("prof1234");
				p.setRole(Role.PROFESSOR);
				p.setBiometricToken(profDefs[i][1]);
				profs[i] = userRepo.save(p);
			}

			// ══════════════════════════════════════════════════════════
			//  ÉTUDIANTS  (générés par boucle, 50-60 par groupe)
			// ══════════════════════════════════════════════════════════
			String[] firstNames = {
				"Alice","Bob","Camille","Damien","Emma","Florian","Grace","Hugo",
				"Ines","Julien","Karim","Leila","Marc","Nadia","Omar","Pierre",
				"Rania","Sami","Tina","Ugo","Vera","Walid","Yasmine","Zakaria",
				"Amira","Bilal","Clara","Dina","Elias","Fatima"
			};
			String[] lastNames = {
				"Morel","Petit","Roy","Garcia","Blanc","Henry","Simon","Richard",
				"David","Thomas","Bernard","Dubois","Laurent","Michel","Lefevre",
				"Martin","Durand","Moreau","Girard","Roux","Vincent","Fournier",
				"Faure","Rousseau","Guerin","Muller","Leroy","Bonnet","Dupont","Lemaire"
			};

			List<User[]> studentsByGroup = new ArrayList<>();
			int gIdx = 0;
			for (int gi = 0; gi < groups.length; gi++) {
				int size = (int) groupDefs[gi][3];
				User[] gs = new User[size];
				for (int si = 0; si < size; si++) {
					String fn = firstNames[gIdx % firstNames.length];
					String ln = lastNames[(gIdx * 7 + 3) % lastNames.length];
					User s = new User();
					s.setEmail(fn.toLowerCase() + "." + ln.toLowerCase() + (gIdx + 1) + "@etu.fr");
					s.setPassword("etudiant1234");
					s.setRole(Role.STUDENT);
					s.setBiometricToken("bio-stu-" + String.format("%04d", gIdx + 1));
					s.setGroup(groups[gi]);
					gs[si] = userRepo.save(s);
					groups[gi].enrollStudent();
					gIdx++;
				}
				groupRepo.save(groups[gi]);
				studentsByGroup.add(gs);
			}

			// ══════════════════════════════════════════════════════════
			//  COURS  (pas de filière)
			// ══════════════════════════════════════════════════════════
			String[][] courseDefs = {
				{"Mathématiques Appliquées", "MATH-301"},
				{"Algorithmique Avancée",    "ALGO-201"},
				{"Informatique Distribuée",  "INFO-402"},
				{"Réseaux & Sécurité",       "RESX-301"},
				{"Physique Quantique",       "PHYS-201"},
				{"Anglais Professionnel",    "ANGL-101"},
				{"Systèmes d'Exploitation",  "SYS-302"},
				{"Analyse de Données",       "DATA-401"},
			};
			Course[] courses = new Course[courseDefs.length];
			for (int i = 0; i < courseDefs.length; i++) {
				Course c = new Course();
				c.setTitle(courseDefs[i][0]);
				c.setCode(courseDefs[i][1]);
				courses[i] = courseRepo.save(c);
			}

			// ══════════════════════════════════════════════════════════
			//  SESSIONS + PRÉSENCES
			//
			//  Groupes   : 0=API-1A 1=API-1B 2=API-1C 3=API-1D 4=API-1E
			//               5=API-2A 6=API-2B 7=API-2C 8=CI-1   9=CI-2
			//  Cours     : 0=MATH 1=ALGO 2=INFO 3=RESX 4=PHYS 5=ANGL 6=SYS 7=DATA
			//  Profs     : 0=Dupont 1=Martin 2=Leroy 3=Benali 4=Roux 5=Faure
			//
			//  Patterns  : 0=normal(88%P,7%L) 1=excellent(95%P,3%L)
			//               2=highAbsence(50%P,8%L) 3=crisis(30%P,5%L)
			//               4=belowAvg(75%P,10%L)
			//
			//  {courseIdx, profIdx, groupIdx, daysAgo, startHour, durH, salle, patternIdx}
			// ══════════════════════════════════════════════════════════
			Object[][] sessionDefs = {
				// ── MATH-301 ──────────────────────────────────────
				{0, 0, 0, 28, 8,  2, "A101", 1},
				{0, 0, 0, 21, 8,  2, "A101", 0},
				{0, 0, 0, 14, 8,  2, "A101", 0},
				{0, 0, 0,  7, 8,  2, "A101", 4},
				{0, 0, 8, 26, 10, 2, "A102", 1},
				{0, 0, 8, 19, 10, 2, "A102", 0},
				{0, 0, 8, 12, 10, 2, "A102", 2},
				{0, 0, 8,  5, 10, 2, "A102", 0},

				// ── ALGO-201 ──────────────────────────────────────
				{1, 1, 1, 27, 10, 2, "B201", 0},
				{1, 1, 1, 20, 10, 2, "B201", 1},
				{1, 1, 1, 13, 10, 2, "B201", 2},
				{1, 1, 1,  6, 10, 2, "B201", 0},
				{1, 1, 5, 25, 14, 2, "B202", 0},
				{1, 1, 5, 18, 14, 2, "B202", 1},
				{1, 1, 5, 11, 14, 2, "B202", 3},
				{1, 1, 5,  4, 14, 2, "B202", 4},

				// ── INFO-402 ──────────────────────────────────────
				{2, 2, 5, 24, 8,  2, "C301", 1},
				{2, 2, 5, 17, 8,  2, "C301", 0},
				{2, 2, 5, 10, 8,  2, "C301", 0},
				{2, 2, 5,  3, 8,  2, "C301", 4},
				{2, 2, 9, 23, 14, 2, "C302", 0},
				{2, 2, 9, 16, 14, 2, "C302", 1},
				{2, 2, 9,  9, 14, 2, "C302", 2},
				{2, 2, 9,  2, 14, 2, "C302", 0},

				// ── RESX-301 ──────────────────────────────────────
				{3, 3, 8, 22, 14, 2, "D401", 1},
				{3, 3, 8, 15, 14, 2, "D401", 0},
				{3, 3, 8,  8, 14, 2, "D401", 0},
				{3, 3, 8,  1, 14, 2, "D401", 2},
				{3, 3, 9, 21, 16, 2, "D402", 0},
				{3, 3, 9, 14, 16, 2, "D402", 1},
				{3, 3, 9,  7, 16, 2, "D402", 4},

				// ── PHYS-201 ──────────────────────────────────────
				{4, 4, 2, 20, 10, 2, "E101", 0},
				{4, 4, 2, 13, 10, 2, "E101", 2},
				{4, 4, 2,  6, 10, 2, "E101", 0},
				{4, 4, 3, 19, 14, 2, "E102", 1},
				{4, 4, 3, 12, 14, 2, "E102", 0},
				{4, 4, 3,  5, 14, 2, "E102", 3},

				// ── ANGL-101 ──────────────────────────────────────
				{5, 0, 0, 26, 16, 2, "F201", 0},
				{5, 0, 0, 19, 16, 2, "F201", 1},
				{5, 0, 0, 12, 16, 2, "F201", 0},
				{5, 0, 0,  5, 16, 2, "F201", 4},
				{5, 5, 5, 25, 16, 2, "F202", 0},
				{5, 5, 5, 18, 16, 2, "F202", 0},
				{5, 5, 5, 11, 16, 2, "F202", 2},
				{5, 5, 6, 24, 16, 2, "F203", 1},
				{5, 5, 6, 17, 16, 2, "F203", 0},
				{5, 5, 6, 10, 16, 2, "F203", 0},

				// ── SYS-302 ───────────────────────────────────────
				{6, 5, 6, 22, 8,  2, "G101", 0},
				{6, 5, 6, 15, 8,  2, "G101", 1},
				{6, 5, 6,  8, 8,  2, "G101", 0},
				{6, 5, 8, 21, 10, 2, "G102", 0},
				{6, 5, 8, 14, 10, 2, "G102", 2},
				{6, 5, 8,  7, 10, 2, "G102", 1},

				// ── DATA-401 ──────────────────────────────────────
				{7, 4, 9, 20, 8,  2, "H201", 1},
				{7, 4, 9, 13, 8,  2, "H201", 0},
				{7, 4, 9,  6, 8,  2, "H201", 4},
				{7, 4, 7, 19, 14, 2, "H202", 0},
				{7, 4, 7, 12, 14, 2, "H202", 0},
				{7, 4, 7,  5, 14, 2, "H202", 2},
			};

			// presentRate, lateRate  (absent = 1 - present - late, pas d'enregistrement)
			double[][] patterns = {
				{0.88, 0.07},  // 0: NORMAL
				{0.95, 0.03},  // 1: EXCELLENT
				{0.50, 0.08},  // 2: HIGH_ABSENCE
				{0.30, 0.05},  // 3: CRISIS
				{0.75, 0.10},  // 4: BELOW_AVERAGE
			};

			double baseLat = 36.7065, baseLon = 3.0786; // Alger
			int qrCounter = 1;

			for (Object[] def : sessionDefs) {
				int cIdx    = (int) def[0];
				int pIdx    = (int) def[1];
				int grpIdx  = (int) def[2];
				int daysAgo = (int) def[3];
				int hour    = (int) def[4];
				int durH    = (int) def[5];
				String sl   = (String) def[6];
				int patIdx  = (int) def[7];

				Session sess = new Session();
				sess.setCourse(courses[cIdx]);
				sess.setProfessor(profs[pIdx]);
				sess.setGroup(groups[grpIdx]);
				sess.setStartTime(LocalDateTime.now()
						.minusDays(daysAgo).withHour(hour).withMinute(0).withSecond(0).withNano(0));
				sess.setEndTime(LocalDateTime.now()
						.minusDays(daysAgo).withHour(hour + durH).withMinute(0).withSecond(0).withNano(0));
				sess.setQrCodeToken("QR-" + courses[cIdx].getCode() + "-" + String.format("%03d", qrCounter++));
				sess.setSalle(sl);
				sess.setLatitude(baseLat + rand.nextDouble() * 0.005);
				sess.setLongitude(baseLon + rand.nextDouble() * 0.005);
				sess.setRadiusInMeters(50.0);
				sessionRepo.save(sess);

				// Présences
				User[] groupStudents = studentsByGroup.get(grpIdx);
				double presentRate = patterns[patIdx][0];
				double lateRate    = patterns[patIdx][1];

				for (User student : groupStudents) {
					double r = rand.nextDouble();
					AttendanceStatus status;
					int minAfter;
					if (r < presentRate) {
						status   = AttendanceStatus.PRESENT;
						minAfter = 2 + rand.nextInt(8);       // 2-9 min
					} else if (r < presentRate + lateRate) {
						status   = AttendanceStatus.LATE;
						minAfter = 16 + rand.nextInt(20);     // 16-35 min
					} else {
						continue; // ABSENT = pas d'enregistrement
					}
					Attendance a = new Attendance();
					a.setStudent(student);
					a.setSession(sess);
					a.setStatus(status);
					a.setScanTime(sess.getStartTime().plusMinutes(minAfter));
					a.setIsOfflineSync(false);
					a.setDeviceId("dev-" + student.getBiometricToken());
					a.setScanLatitude(sess.getLatitude()  + (rand.nextDouble() * 0.0004 - 0.0002));
					a.setScanLongitude(sess.getLongitude() + (rand.nextDouble() * 0.0004 - 0.0002));
					attendanceRepo.save(a);
				}
			}

			// ── SESSION LIVE (aujourd'hui, en cours) ─────────────────
			Session live = new Session();
			live.setCourse(courses[2]); // INFO-402
			live.setProfessor(profs[2]);
			live.setGroup(groups[5]);   // API-2 A
			live.setStartTime(LocalDateTime.now().minusHours(1).withMinute(0).withSecond(0).withNano(0));
			live.setEndTime(LocalDateTime.now().plusHours(1).withMinute(0).withSecond(0).withNano(0));
			live.setQrCodeToken("QR-LIVE-" + String.format("%03d", qrCounter++));
			live.setSalle("C301");
			live.setLatitude(baseLat);
			live.setLongitude(baseLon);
			live.setRadiusInMeters(50.0);
			sessionRepo.save(live);

			User[] liveStudents = studentsByGroup.get(5);
			int checkedIn = (int) (liveStudents.length * 0.72); // 72% déjà pointés
			for (int i = 0; i < checkedIn; i++) {
				Attendance a = new Attendance();
				a.setStudent(liveStudents[i]);
				a.setSession(live);
				a.setStatus(i < checkedIn * 0.92 ? AttendanceStatus.PRESENT : AttendanceStatus.LATE);
				a.setScanTime(live.getStartTime().plusMinutes(2 + rand.nextInt(50)));
				a.setIsOfflineSync(false);
				a.setDeviceId("dev-" + liveStudents[i].getBiometricToken());
				a.setScanLatitude(baseLat + rand.nextDouble() * 0.0002);
				a.setScanLongitude(baseLon + rand.nextDouble() * 0.0002);
				attendanceRepo.save(a);
			}

			System.out.println("[DataSeed] Injection terminée :");
			System.out.println("  - " + groupRepo.count()      + " groupes");
			System.out.println("  - " + userRepo.count()       + " utilisateurs (1 admin, 6 profs, ~546 étudiants)");
			System.out.println("  - " + courseRepo.count()     + " cours");
			System.out.println("  - " + sessionRepo.count()    + " sessions (dont 1 en cours)");
			System.out.println("  - " + attendanceRepo.count() + " présences enregistrées");
		};
	}
}
