import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String get googleVisionApiKey =>
      dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
}
