import 'package:flutter/material.dart';
import '../screens/library/library_screen.dart';
import '../screens/reader/reader_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/voice_settings_screen.dart';
import '../screens/onboarding/import_screen.dart';
import '../models/book.dart';

class AppRoutes {
  static const String library = '/';
  static const String reader = '/reader';
  static const String settings = '/settings';
  static const String voiceSettings = '/voice-settings';
  static const String importBook = '/import';

  static Map<String, WidgetBuilder> get routes => {
    library: (_) => const LibraryScreen(),
    settings: (_) => const SettingsScreen(),
    voiceSettings: (_) => const VoiceSettingsScreen(),
    importBook: (_) => const ImportScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == reader) {
      final book = settings.arguments as Book;
      return MaterialPageRoute(builder: (_) => ReaderScreen(book: book));
    }
    return MaterialPageRoute(builder: (_) => const LibraryScreen());
  }
}
