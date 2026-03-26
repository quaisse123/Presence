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

Future<Map<String, dynamic>> fetchMySessionHistory({
  String? period,
  String? status,
  String? search,
}) async {
  final token = await getValidAccessToken();

  final queryParams = <String, String>{};

  if (period != null && period.trim().isNotEmpty) {
    queryParams['period'] = period.trim();
  }

  if (status != null && status.trim().isNotEmpty) {
    queryParams['status'] = status.trim();
  }

  if (search != null && search.trim().isNotEmpty) {
    queryParams['search'] = search.trim();
  }

  final uri = Uri.parse(
    '${apiUrl}/sessions/my-history',
  ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  throw Exception(
    'Failed to fetch student session history (${response.statusCode})',
  );
}

Future<String> fetchQrToken({required int sessionId}) async {
  final token = await getValidAccessToken();
  final response = await http.get(
    Uri.parse('${apiUrl}/jwt/generate-qr-token?sessionId=$sessionId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to fetch QR token');
  }
}
