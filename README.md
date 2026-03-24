# Presence App

Presence App est une application de gestion de presence pour un contexte universitaire, avec deux parcours:
- Parcours professeur: gestion des cours, suivi des sessions, affichage QR, consultation de presence.
- Parcours etudiant: scan QR, enregistrement de presence, historique personnel.

Le projet est compose de:
- Un backend Java Spring Boot (API REST + JWT + base H2).
- Un frontend Flutter (mobile/web) pour les interfaces utilisateur.

## 1) Vision fonctionnelle

### Objectif metier
Permettre de marquer la presence en cours via un QR code dynamique, avec un suivi des presences par etudiant et par session.

### Professeur - ce qui existe
- Se connecter.
- Voir les sessions (liste, pagination, filtres visuels).
- Ouvrir le detail d une session.
- Afficher un QR code dynamique pour la session.
- Voir les cours.
- Creer un cours.
- Supprimer un cours.

### Etudiant - ce qui existe
- Se connecter.
- Voir son dashboard de presence.
- Scanner un QR code de session.
- Recevoir un resultat de scan (succes/erreur + details).
- Consulter son historique de presences avec filtres (periode, statut, recherche).

### Regles metier actuellement appliquees
- Le QR de presence est un JWT court genere cote backend.
- Le scan verifie que le token QR est valide, de bon type, et lie a une session.
- Le scan verifie que la session est active au moment du scan.
- Le scan verifie la correspondance du groupe etudiant/session.

### Limites fonctionnelles actuelles
- Creation de session professeur non finalisee cote API/UI.
- Fermeture manuelle de session non exposee en endpoint.
- Feuille de presence complete par session non exposee en endpoint dedie.
- Sync offline batch non implementee.
- Verification GPS et calcul LATE encore simplifies.

## 2) Architecture technique

## Vue d ensemble
- Frontend Flutter consomme une API REST JSON.
- Backend Spring Boot applique la logique metier et persiste les donnees en H2.
- Authentification basee JWT (access + refresh).
- QR de presence = JWT court dedie a une session.

## Backend (Spring Boot)
- Langage: Java 17.
- Framework: Spring Boot.
- Modules principaux: Web MVC, Data JPA, Security.
- Base de donnees: H2 (mode fichier local persistant).
- Mapping DTO: ModelMapper.
- Token: JJWT.

### Couches backend
- Entities: modeles de donnees (`User`, `Course`, `Session`, `Attendance`, `Group`).
- Repositories: acces BDD via JPA.
- Services/Managers: logique metier.
- Controllers: endpoints REST exposes au frontend.

### Modele de donnees simplifie
- `User`: email, password, role, groupe.
- `Course`: titre, code.
- `Session`: plage horaire, cours, professeur, groupe, token QR.
- `Attendance`: etudiant, session, statut, heure de scan, metadata device/GPS.
- `Group`: niveau/section/filiere + total etudiants.

## Frontend (Flutter)
- Langage: Dart.
- Framework: Flutter + Material.
- Gestion API: package `http`.
- Gestion token local: `shared_preferences`.
- Navigation: GetX + Navigator.
- Scan QR: `mobile_scanner`.
- Affichage QR: `qr_flutter`.

### Organisation frontend
- `lib/Api`: appels HTTP vers le backend.
- `lib/pages`: pages principales (login, dashboards, details, scan).
- `lib/components`: composants reutilisables (modal QR, formulaire creation cours).
- `lib/config`: config route role et URL API.

## 3) Parcours applicatifs

### Login et role
1. L utilisateur envoie email/password.
2. Le backend retourne accessToken + refreshToken.
3. Le frontend stocke les tokens localement.
4. Le role extrait du JWT decide la page d entree (professeur ou etudiant).

### Flux QR professeur -> etudiant
1. Le professeur ouvre une session et affiche le QR.
2. Le frontend appelle `/api/jwt/generate-qr-token?sessionId=...`.
3. Le backend genere un JWT court avec `type=attendance_qr` et `sessionId`.
4. L etudiant scanne le QR et envoie le token a `/api/attendance/scan`.
5. Le backend valide token, session active, groupe, puis enregistre la presence.

### Historique etudiant
1. Le frontend appelle `/api/attendance/my` avec filtres optionnels.
2. Le backend retourne:
- Liste detaillee des presences.
- Statistiques: total sessions, sessions assistees, sessions manquees.

## 4) API principale (etat actuel)

## Auth/JWT
- `POST /api/auth/login`
- `POST /api/jwt/refresh`
- `GET /api/jwt/ping`
- `GET /api/jwt/generate-qr-token?sessionId={id}`

## Cours
- `GET /api/courses?page={p}&size={s}`
- `POST /api/courses`
- `DELETE /api/courses/{id}`
- `GET /api/courses/check-code?code={code}`

## Sessions
- `GET /api/sessions?page={p}&size={s}`
- `GET /api/sessions/{id}`

## Presence
- `POST /api/attendance/scan`
- `GET /api/attendance/my?period=...&status=...&search=...`

## 5) Installation et execution

## Prerequis
- Java 17+
- Maven (ou wrapper Maven fourni)
- Flutter SDK
- Android Studio/Xcode (selon cible)

## Lancer le backend
Depuis le dossier `backend`:

```powershell
.\mvnw.cmd spring-boot:run
```

Le backend demarre sur `http://localhost:8080`.

Console H2 (dev):
- URL: `http://localhost:8080/h2-console`

## Lancer le frontend
Depuis le dossier `frontend`:

```powershell
flutter pub get
flutter run
```

Notes URL API:
- Web: utilise `localhost`.
- Emulateur Android: peut utiliser `10.0.2.2`.
- Mobile physique: utiliser l IP locale du PC dans la config API.

## 6) Securite et qualite (etat actuel)

## Points positifs
- JWT access/refresh en place.
- QR court dedie a la presence.
- Separation backend/frontend claire.
- DTO dedies pour les reponses UI.

## Points a renforcer
- Password encore compare en clair (a migrer vers BCrypt).
- Secret JWT present en fichier local (a externaliser via variable d environnement).
- CORS tres ouvert pour dev (a restreindre en preprod/prod).
- Verification GPS/LATE a finaliser dans la logique metier.

## 7) Roadmap recommandee

- Finaliser `SessionManager` (create/update/delete/close session).
- Ajouter endpoint de feuille de presence par session.
- Implementer geofence Haversine reel + regle LATE configurable.
- Ajouter sync offline batch avec validation robuste.
- Durcir la securite (BCrypt, secrets, CORS, roles endpoint par endpoint).
- Ajouter tests backend (service + integration) et tests Flutter critiques.

## 8) Structure du repository

- `backend/`: API Spring Boot, logique metier, persistence.
- `frontend/`: application Flutter (professeur + etudiant).
- `backend/Plan.md`: plan fonctionnel initial du MVP.

## 9) Resume executif

Presence App est deja une base solide avec:
- Auth JWT operationnelle.
- Flux QR presence fonctionnel de bout en bout.
- Dashboards professeur/etudiant utilisables.

Pour une version production, les priorites sont:
- Completer les endpoints sessions/presence manquants.
- Finaliser la logique GPS/LATE.
- Renforcer la securite et la couverture de tests.
