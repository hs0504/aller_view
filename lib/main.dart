import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env 파일이 없으면 API 키 없이 진행 (키 미설정 상태로 처리)
  }

  await Supabase.initialize(
    url: dotenv.env['REACT_APP_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['REACT_APP_SUPABASE_PUBLISHABLE_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
