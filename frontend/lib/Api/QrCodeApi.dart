import 'dart:convert';
import 'dart:ffi';

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

  Map<String, dynamic> claims = Jwt.parseJwt(token);
  if (claims.containsKey('userId')) {
    return claims['userId'] as int;
  } else {
    throw Exception('User ID not found in token');
  }
}
