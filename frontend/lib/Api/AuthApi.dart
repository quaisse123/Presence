import 'dart:convert';
import 'package:frontend/Api/JwtService.dart';
import 'package:frontend/config/apiUrl.dart';
import 'package:frontend/pages/login.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> login(String email, String password) async {
  final url = Uri.parse('${apiUrl}/auth/login');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
  }
}

Future<Map<String, dynamic>> sendActivationPin(String email) async {
  final url = Uri.parse('${apiUrl}/auth/activation/send-pin');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to send PIN');
  }
}

Future<Map<String, dynamic>> verifyActivationPin(
  String email,
  String pin,
) async {
  final url = Uri.parse('${apiUrl}/auth/activation/verify-pin');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'pin': pin}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
      jsonDecode(response.body)['error'] ?? 'Failed to verify PIN',
    );
  }
}

Future<Map<String, dynamic>> completeActivationProfile({
  required String email,
  required String firstName,
  required String lastName,
  required String apogeeCode,
  required String password,
  required String level,
  String? section,
  String? major,
}) async {
  final url = Uri.parse('${apiUrl}/auth/activation/complete-profile');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'apogeeCode': apogeeCode,
      'password': password,
      'level': level,
      'section': section,
      'major': major,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
      jsonDecode(response.body)['error'] ?? 'Failed to complete activation',
    );
  }
}

Future<bool> isUserLoggedIn() async {
  try {
    final token = await getValidAccessToken();
    return token.isNotEmpty;
  } catch (e) {
    // Si getValidAccessToken() lance une exception, l'utilisateur n'est pas connecté
    return false;
  }
}

void logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('accessToken');
  await prefs.remove('refreshToken');
  Get.offAll(() => LoginPage());
}

Future<String?> getUserRole() async {
  final token = await getValidAccessToken();
  if (token.isEmpty) {
    //Token non trouvé
    return null;
  }
  try {
    Map<String, dynamic> claims = Jwt.parseJwt(token);
    return claims['role'] as String?;
  } catch (e) {
    // Token invalide ou claim manquant
    return null;
  }
}
