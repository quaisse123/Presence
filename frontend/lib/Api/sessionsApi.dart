import 'package:frontend/config/apiUrl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> fetchSessions({
  int page = 0,
  int size = 10,
}) async {
  final response = await http.get(
    Uri.parse('${apiUrl}/sessions?page=$page&size=$size'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load sessions');
  }
}

Future<Map<String, dynamic>> fetchSessionDetails(int id) async {
  final response = await http.get(Uri.parse('${apiUrl}/sessions/$id'));
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load session details');
  }
}

Future<String> fetchQrToken() async {
  final response = await http.get(Uri.parse('${apiUrl}/jwt/generate-qr-token'));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to fetch QR token');
  }
}
