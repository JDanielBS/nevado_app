import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'theme.dart';

class NevadoApp extends StatelessWidget {
  const NevadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nevados',
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
