// Importation des constantes de plateforme Flutter
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Retourne dynamiquement la bonne URL backend selon la plateforme.
/// - Web/Chrome/PC : localhost
/// - Android physique : IP locale du PC
/// - Android emulateur: 10.0.2.2 (si --dart-define=USE_ANDROID_EMULATOR=true)
/// - iOS/mobile: IP locale du PC
String get apiUrl {
  // Si l'application tourne dans un navigateur web (Chrome, Edge, etc.)
  if (kIsWeb) {
    // Utilise localhost car le backend tourne sur le même PC
    return 'http://localhost:8080/api';
  }

  // Vérifie si on a passé --dart-define=USE_ANDROID_EMULATOR=true au lancement
  // Cela permet de forcer l'URL spéciale pour l'émulateur Android
  const bool useAndroidEmulator = bool.fromEnvironment(
    'USE_ANDROID_EMULATOR', // Nom de la variable d'environnement
    defaultValue: false, // Par défaut, c'est false (donc mobile physique)
  );

  // Si on est sur Android ET qu'on a demandé l'émulateur
  if (defaultTargetPlatform == TargetPlatform.android && useAndroidEmulator) {
    // Utilise l'URL spéciale pour accéder au backend depuis l'émulateur Android
    return 'http://10.0.2.2:8080/api';
  }

  // Par défaut (mobile physique Android/iOS, desktop, etc.)
  // Utilise l'IP locale du PC sur le réseau WiFi
  // À personnaliser selon l'adresse IP de ta machine
  return 'http://192.168.0.21:8080/api'; // ← Mets ici l’IP locale de ton PC
}
