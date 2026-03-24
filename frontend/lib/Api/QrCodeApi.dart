import 'dart:convert';

import 'package:frontend/Api/JwtService.dart';
import 'package:frontend/config/apiUrl.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

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

Future<Map<String, dynamic>> scanAttendance({
  required String qrCodeToken,
  required int studentId,
  required double scanLatitude,
  required double scanLongitude,
  required String deviceId,
  DateTime? scanTime,
}) async {
  final token = await getValidAccessToken();
  final response = await http.post(
    Uri.parse('${apiUrl}/attendance/scan'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'qrCodeToken': qrCodeToken,
      'studentId': studentId,
      'scanLatitude': scanLatitude,
      'scanLongitude': scanLongitude,
      'deviceId': deviceId,
      'scanTime': (scanTime ?? DateTime.now()).toIso8601String(),
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 400) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  throw Exception('Failed to scan attendance (${response.statusCode})');
}

Future<int> getLoggedUserId() async {
  final token = await getValidAccessToken();

  final Map<String, dynamic> claims = Jwt.parseJwt(token);
  final dynamic rawUserId = claims['userId'] ?? claims['userid'];

  if (rawUserId == null) {
    throw Exception('User ID not found in token');
  }

  if (rawUserId is int) {
    return rawUserId;
  }

  if (rawUserId is num) {
    return rawUserId.toInt();
  }

  if (rawUserId is String) {
    final parsed = int.tryParse(rawUserId);
    if (parsed != null) {
      return parsed;
    }
  }

  throw Exception('Invalid user ID format in token');
}

Future<Map<String, dynamic>> fetchMyAttendances({
  String? period,
  String? status,
  String? search,
}) async {
  final token = await getValidAccessToken();

  final queryParams = <String, String>{};

  // Filtre période (optionnel): LAST_WEEK, LAST_MONTH, ALL
  if (period != null && period.trim().isNotEmpty) {
    queryParams['period'] = period.trim();
  }

  // Filtre statut (optionnel): PRESENT, LATE, ABSENT
  if (status != null && status.trim().isNotEmpty) {
    queryParams['status'] = status.trim();
  }

  // Filtre recherche (optionnel): course title / code / salle
  if (search != null && search.trim().isNotEmpty) {
    queryParams['search'] = search.trim();
  }

  final uri = Uri.parse(
    '${apiUrl}/attendance/my',
  ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  throw Exception(
    'Failed to fetch student attendances (${response.statusCode})',
  );
}
