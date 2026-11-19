import 'dart:io' show Platform;

/// API location.
///
/// Override at build/run time:
///   flutter run --dart-define=API_URL=http://192.168.1.20:4000
///
/// Defaults: the Android emulator reaches the host machine at 10.0.2.2,
/// the iOS simulator at localhost.
class AppConfig {
  static const _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override.replaceAll(RegExp(r'/+$'), '');
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    } catch (_) {}
    return 'http://localhost:4000';
  }

  static String get apiUrl => '$baseUrl/api';

  /// Uploaded files come back as `/uploads/...`; turn them into absolute URLs.
  static String media(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
