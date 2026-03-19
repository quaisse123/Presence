import 'package:flutter/material.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/MainScreen.dart';
import 'package:get/get.dart';
import 'pages/login.dart';
import 'pages/profDash.dart';
import 'pages/studentScanTest.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await isUserLoggedIn();
  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

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
      initialRoute: isLoggedIn ? '/main' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/profDash', page: () => const ProfDashPage()),
        GetPage(name: '/main', page: () => const MainScreen()),
        GetPage(
          name: '/studentScanTest',
          page: () => const StudentScanTestPage(),
        ),
      ],
    );
  }
}
