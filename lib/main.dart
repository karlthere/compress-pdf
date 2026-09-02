import 'package:flutter/material.dart';
import 'ui/theme/app_theme.dart';
import 'ui/views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PdfSqueezerApp());
}

class PdfSqueezerApp extends StatelessWidget {
  const PdfSqueezerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Squeezer Desktop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
