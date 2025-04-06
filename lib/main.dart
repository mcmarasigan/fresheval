import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'l10n.dart';
import 'camera_screen.dart';
import 'scan_history_screen.dart';
import 'settings.dart';
import 'help_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('language') ?? 'en';
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
    languageCode = widget.initialLocale;
  }

  void updateLanguage(String newLanguageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLanguageCode);
    setState(() {
      languageCode = newLanguageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(languageCode);

    return MaterialApp(
      title: 'FreshEval',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA6), // Primary Teal
          primary: const Color(0xFF00BFA6),
          secondary: const Color(0xFF009688), // Accent
          background: const Color(0xFFF9FAFB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyLarge: GoogleFonts.poppins(fontSize: 16),
          bodyMedium: GoogleFonts.poppins(fontSize: 14),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF00BFA6),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF009688)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA6),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFFFFFFFF),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF009688),
          textColor: Colors.black87,
        ),
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
