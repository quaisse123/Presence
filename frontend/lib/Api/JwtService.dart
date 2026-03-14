import 'dart:convert';

// import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/config/apiUrl.dart';
import 'package:frontend/pages/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getValidAccessToken() async {
  var tokens = await getTokens();
  String accessToken = tokens['accessToken'] ?? '';

  // Teste le token sur un endpoint protégé (ex: /api/ping)
  final testUrl = Uri.parse('${apiUrl}/jwt/ping');
  final response = await http.get(
    testUrl,
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  if (response.statusCode == 200) {
    print('[DEBUG] Token valide: Access token is valid.');
  }

  if (response.statusCode == 401 || response.statusCode == 403) {
    // Token expiré ou non authentifié, tente un refresh
    print(
      '[DEBUG] AccessToken expiré (${response.statusCode}): Refreshing token...',
    );
    try {
      await refreshToken();
      print('[DEBUG] Refresh réussi: Nouveau token obtenu.');
    } catch (e) {
      print('[DEBUG] Session expirée: Veuillez vous reconnecter.');
      Get.offAll(() => LoginPage());
    }
    tokens = await getTokens();
    accessToken = tokens['accessToken'] ?? '';
  }

  return accessToken;
}

Future<void> saveTokens(Map<String, dynamic> tokens) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('accessToken', tokens['accessToken'] ?? '');
  await prefs.setString('refreshToken', tokens['refreshToken'] ?? '');
}

// Get tokens
Future<Map<String, String>> getTokens() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'accessToken': prefs.getString('accessToken') ?? '',
    'refreshToken': prefs.getString('refreshToken') ?? '',
  };
}

// Refresh token
Future<void> refreshToken() async {
  final tokens = await getTokens();
  final refreshToken = tokens['refreshToken'] ?? '';

  if (refreshToken.isEmpty) {
    throw Exception('No refresh token found');
  }

  final url = Uri.parse('${apiUrl}/jwt/refresh');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refreshToken': refreshToken}),
  );

  if (response.statusCode == 200) {
    final newTokens = jsonDecode(response.body);
    await saveTokens(newTokens);
  } else if (response.statusCode == 401) {
    // Refresh token expiré ou invalide, supprimer les tokens stockés
    print('[DEBUG] Refresh échoué: Refresh token expiré ou invalide.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    throw Exception('Refresh token expired or invalid. Please log in again.');
  } else {
    print('[DEBUG] Erreur: Échec du refresh token.');
    throw Exception('Failed to refresh token');
  }
}
