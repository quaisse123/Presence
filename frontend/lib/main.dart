import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'pages/profDash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ensam Presence',
      // Material 3 theme required by the dashboard design
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A73E8),
        fontFamily: 'Roboto',
      ),
      // TODO: restore to LoginPage() once auth flow is wired up
      // home: LoginPage(),
      home: const LoginPage(),
      // routes: {
      //   '/login': (_) => LoginPage(),
      //   '/profDash': (_) => const ProfDashPage(),
      // },
    );
  }
}
