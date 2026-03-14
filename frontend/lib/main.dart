import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pages/login.dart';
import 'pages/profDash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ensam Presence',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A73E8),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/profDash', page: () => const ProfDashPage()),
      ],
    );
  }
}
