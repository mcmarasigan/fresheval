import 'package:flutter/material.dart';
import 'package:fresheval/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String)
      onLanguageChanged; // Callback to notify language change
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
  String? _selectedLanguage; // Allow null until the language is loaded
  late AppLocalizations _localization; // Dynamic localization instance

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _localization = widget.localizations; // Initialize localization
  }

  // Load the saved language preference
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage =
          prefs.getString('language') ?? 'en'; // Default to English
    });
  }

  // Save the selected language preference and update localization dynamically
  Future<void> _saveLanguagePreference(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _selectedLanguage = language;
      _localization = AppLocalizations(language); // Update localization
    });

    // ✅ Notify the entire app of the language change
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

  // Show confirmation dialog
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
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text(_localization.getTranslation('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onConfirmed(); // Execute the confirmed action
              },
              child: Text(_localization.getTranslation('confirm')),
            ),
          ],
        );
      },
    );
  }

  // Clear scan history
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

  // Clear cache
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
    // Show a loading indicator until _selectedLanguage is loaded
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

    // Ensure _selectedLanguage matches the DropdownMenuItem values
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
      _selectedLanguage = 'en'; // Fallback to a valid default
    }

    return Scaffold(
      drawer: _buildDrawer(), // ✅ Match Camera Screen
      appBar: AppBar(
        title: Text(_localization.getTranslation('settings')),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text(_localization.getTranslation('language')),
              subtitle: Text(
                _selectedLanguage == 'en'
                    ? _localization.getTranslation('english')
                    : _localization.getTranslation('tagalog'),
              ),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                items: dropdownItems,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _saveLanguagePreference(newValue);
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(_localization.getTranslation('clear scan history')),
              onTap: () {
                _showConfirmationDialog(
                  title: _localization.getTranslation('clear scan history'),
                  content:
                      _localization.getTranslation('confirm_clear_history'),
                  onConfirmed: _clearScanHistory,
                );
              },
              trailing: const Icon(Icons.delete),
            ),
            const Divider(),
            ListTile(
              title: Text(_localization.getTranslation('clear cache')),
              onTap: () {
                _showConfirmationDialog(
                  title: _localization.getTranslation('clear cache'),
                  content: _localization.getTranslation('confirm_clear_cache'),
                  onConfirmed: _clearCache,
                );
              },
              trailing: const Icon(Icons.delete_forever),
            ),
          ],
        ),
      ),
    );
  }

  /// **📌 Navigation Drawer (Same as Camera Screen)**
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("FreshEval"),
            accountEmail: const Text("Scan and evaluate freshness"),
            decoration: const BoxDecoration(color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text("Camera"),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Scan History"),
            onTap: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context); // Stay on this page
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help"),
            onTap: () {
              Navigator.pushNamed(context, '/help');
            },
          ),
        ],
      ),
    );
  }
}
