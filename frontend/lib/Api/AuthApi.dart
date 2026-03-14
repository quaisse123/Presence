import 'dart:convert';
import 'package:frontend/config/apiUrl.dart';
import 'package:http/http.dart' as http;

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
