import 'package:flutter/material.dart';
import 'package:frontend/MainScreen.dart';
import 'package:frontend/pages/studentDash.dart';

final Map<String, Widget Function()> rolePageFactory = {
  'PROFESSOR': () => const MainScreen(),
  'STUDENT': () => const StudentDashPage(),
};

Widget getPageForRole(String? role) {
  return rolePageFactory[role?.toUpperCase()]?.call() ?? const MainScreen();
}
