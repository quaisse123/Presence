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

/// Crée une session (professeur). Retourne la session créée.
Future<Map<String, dynamic>> createSession({
  required String startTime,
  required String endTime,
  double? latitude,
  double? longitude,
  double? radiusInMeters,
  String? salle,
  String? description,
  required int courseId,
  required int groupId,
}) async {
  final token = await getValidAccessToken();
  final response = await http.post(
    Uri.parse('${apiUrl}/sessions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'startTime': startTime,
      'endTime': endTime,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'salle': salle,
      'description': description,
      'courseId': courseId,
      'groupId': groupId,
    }),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to create session: ${response.body}');
  }
}

/// Ferme une session (met endTime à maintenant).
Future<void> closeSession(int sessionId) async {
  final token = await getValidAccessToken();
  final response = await http.put(
    Uri.parse('${apiUrl}/sessions/$sessionId/close'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to close session: ${response.body}');
  }
}

/// Liste tous les groupes (pour le formulaire de création de session).
Future<List<Map<String, dynamic>>> fetchGroups() async {
  final token = await getValidAccessToken();
  final response = await http.get(
    Uri.parse('${apiUrl}/groups'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final body = json.decode(response.body);
    return (body as List).cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load groups');
  }
}
