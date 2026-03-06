import 'package:frontend/config/apiUrl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> fetchCourses({int page = 0, int size = 10}) async {
  final response = await http.get(
    Uri.parse('${apiUrl}/courses?page=$page&size=$size'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load courses');
  }
}

Future<void> createCourse({required String title, required String code}) async {
  final response = await http.post(
    Uri.parse('${apiUrl}/courses'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'title': title, 'code': code}),
  );
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to create course');
  }
}

Future<void> deleteCourse(int id) async {
  final response = await http.delete(Uri.parse('$apiUrl/courses/$id'));
  if (response.statusCode != 204) {
    throw Exception('Failed to delete course');
  }
}

/// Checks if a course code is available (not already taken).
/// Returns true if available, false if already used.
Future<bool> checkCourseCodeAvailability(String code) async {
  final response = await http.get(
    Uri.parse('${apiUrl}/courses/check-code?code=${Uri.encodeComponent(code)}'),
  );
  if (response.statusCode == 200) {
    // The backend returns a boolean as plain text (true/false)
    final body = response.body.trim().toLowerCase();
    return body == 'true';
  } else {
    throw Exception('Failed to check code availability');
  }
}
