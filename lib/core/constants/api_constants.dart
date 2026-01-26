import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get graphqlEndpoint =>
      dotenv.env['API_URL'] ?? 'https://api.ssp.app/graphql';

  static int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  static String get nfcBaseUrl =>
      dotenv.env['NFC_BASE_URL'] ?? 'https://ssp.app/t';
}

class AppConfig {
  static bool get debugMode =>
      dotenv.env['ENABLE_DEBUG_MODE']?.toLowerCase() == 'true';

  static bool get mockNfc =>
      dotenv.env['ENABLE_MOCK_NFC']?.toLowerCase() == 'true';

  static String get appName => dotenv.env['APP_NAME'] ?? 'SSP NFC Config';

  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
}
