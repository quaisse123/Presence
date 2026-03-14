import 'package:frontend/config/apiUrl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/Api/JwtService.dart';

Future<Map<String, dynamic>> fetchSessions({
  int page = 0,
  int size = 10,
}) async {
  final token = await getValidAccessToken();
  final response = await http.get(
    Uri.parse('${apiUrl}/sessions?page=$page&size=$size'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load sessions ${response.statusCode}');
  }
}

Future<Map<String, dynamic>> fetchSessionDetails(int id) async {
  final token = await getValidAccessToken();
  final response = await http.get(
    Uri.parse('${apiUrl}/sessions/$id'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load session details');
  }
}

Future<String> fetchQrToken() async {
  final token = await getValidAccessToken();
  final response = await http.get(
    Uri.parse('${apiUrl}/jwt/generate-qr-token'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to fetch QR token');
  }
}
