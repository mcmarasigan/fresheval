import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n.dart';
import 'camera_screen.dart';
import 'scan_history_screen.dart';
import 'settings.dart';
import 'help_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final languageCode =
      prefs.getString('language') ?? 'en'; // Default to English
  runApp(MyApp(initialLocale: languageCode));
}

class MyApp extends StatefulWidget {
  final String initialLocale;

  const MyApp({super.key, required this.initialLocale});

  @override
  _MyAppState createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  late String languageCode;

  @override
  void initState() {
    super.initState();
    languageCode = widget.initialLocale; // Initialize with the provided locale
  }

  // Function to update the app's language dynamically
  void updateLanguage(String newLanguageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLanguageCode); // Save preference
    setState(() {
      languageCode = newLanguageCode; // Update state
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(languageCode);

    return MaterialApp(
      title: 'FreshEval',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF3F4D3),
      ),
      locale: Locale(languageCode),
      supportedLocales: const [Locale('en'), Locale('tl')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const CameraScreen(),
      routes: {
        '/history': (context) =>
            ScanHistoryScreen(localizations: localizations),
        '/settings': (context) => SettingsScreen(
              localizations: localizations,
              onLanguageChanged: updateLanguage,
            ),
        '/help': (context) => HelpScreen(localizations: localizations),
      },
    );
  }
}
