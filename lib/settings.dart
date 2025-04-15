import 'package:flutter/material.dart';
import 'package:fresheval/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String) onLanguageChanged;
  final AppLocalizations localizations;

  const SettingsScreen({
    super.key,
    required this.onLanguageChanged,
    required this.localizations,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedLanguage;
  late AppLocalizations _localization;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _localization = widget.localizations;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _saveLanguagePreference(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _selectedLanguage = language;
      _localization = AppLocalizations(language);
    });

    widget.onLanguageChanged(language);
    MyApp.of(context)?.updateLanguage(language);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_localization.getTranslation('language_set_to')} ${language == 'en' ? _localization.getTranslation('english') : _localization.getTranslation('tagalog')}',
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirmed,
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_localization.getTranslation('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirmed();
              },
              child: Text(_localization.getTranslation('confirm')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_scans');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${_localization.getTranslation('scan history')} cleared.'),
      ),
    );
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_localization.getTranslation('cache')} cleared.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color greenColor = Color(0xFF059212);
    const Color grayColor = Color(0xFF787878);

    if (_selectedLanguage == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.localizations.getTranslation('settings')),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final dropdownItems = [
      DropdownMenuItem(
        value: 'en',
        child: Text(_localization.getTranslation('english')),
      ),
      DropdownMenuItem(
        value: 'tl',
        child: Text(_localization.getTranslation('tagalog')),
      ),
    ];

    if (!dropdownItems.any((item) => item.value == _selectedLanguage)) {
      _selectedLanguage = 'en';
    }

    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(
                Icons.menu,
                color: greenColor,
                size: 30,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(
          _localization.getTranslation('settings'),
          style: TextStyle(color: greenColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: greenColor, width: 1),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors
                    .white, // Changed to white (or use Colors.transparent for no filler)
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                title: Text(
                  _localization.getTranslation('language'),
                  style: TextStyle(color: greenColor),
                ),
                subtitle: Text(
                  _selectedLanguage == 'en'
                      ? _localization.getTranslation('english')
                      : _localization.getTranslation('tagalog'),
                  style: TextStyle(color: grayColor),
                ),
                trailing: Icon(Icons.arrow_drop_down, color: greenColor),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(_localization.getTranslation('language')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: dropdownItems.map((item) {
                          return ListTile(
                            title: item.child,
                            onTap: () {
                              _saveLanguagePreference(item.value!);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: greenColor, width: 1),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors
                    .white, // Changed to white (or use Colors.transparent for no filler)
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                title: Text(
                  _localization.getTranslation('clear scan history'),
                  style: TextStyle(color: greenColor),
                ),
                onTap: () {
                  _showConfirmationDialog(
                    title: _localization.getTranslation('clear scan history'),
                    content:
                        _localization.getTranslation('confirm_clear_history'),
                    onConfirmed: _clearScanHistory,
                  );
                },
                trailing: Icon(Icons.delete, color: greenColor),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: greenColor, width: 1),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors
                    .white, // Changed to white (or use Colors.transparent for no filler)
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                title: Text(
                  _localization.getTranslation('clear cache'),
                  style: TextStyle(color: greenColor),
                ),
                onTap: () {
                  _showConfirmationDialog(
                    title: _localization.getTranslation('clear cache'),
                    content:
                        _localization.getTranslation('confirm_clear_cache'),
                    onConfirmed: _clearCache,
                  );
                },
                trailing: Icon(Icons.delete, color: greenColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    const Color selectedColor = Color(0xFF059212);
    const Color unselectedColor = Color(0xFF787878);

    bool isRouteActive(String routeName) {
      return ModalRoute.of(context)?.settings.name == routeName;
    }

    return Drawer(
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FRESHEVAL',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.camera,
                    color: isRouteActive('/camera')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    "Camera",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/camera')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/camera')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor: isRouteActive('/camera') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/camera');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.history,
                    color: isRouteActive('/history')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    "Scan History",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/history')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/history')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor:
                      isRouteActive('/history') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/history');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: isRouteActive('/settings')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    "Settings",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/settings')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/settings')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor:
                      isRouteActive('/settings') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/settings');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.help,
                    color: isRouteActive('/help')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    "Help",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/help')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/help')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor: isRouteActive('/help') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/help');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.info,
                    color: isRouteActive('/developers')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    "Developers",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/developers')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/developers')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor:
                      isRouteActive('/developers') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/developers');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
