import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> fetchData() async {
  final response = await http.get(
    Uri.parse('http://84.235.230.47:8080/test/all'),
  );

  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        print('Réponse JSON inattendue : \\${response.body}');
        return {};
      }
    } catch (e) {
      print('Erreur de décodage JSON : $e');
      print(
        'Corps de la réponse : \\n${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );
      return {};
    }
  } else {
    print('Erreur HTTP : \\${response.statusCode}');
    print(
      'Corps de la réponse : \\n${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
    );
    return {};
  }
}
