import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String) onLanguageChanged; // Callback to notify language change
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
  int _currentIndex = 2; // Current tab index
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
      _selectedLanguage = prefs.getString('language') ?? 'en'; // Default to English
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

    // Notify the app of the language change
    widget.onLanguageChanged(language);

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
        content: Text('${_localization.getTranslation('scan history')} cleared.'),
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

  // Handle bottom navigation
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/history');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/settings');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/help');
    }
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
      appBar: AppBar(
        title: Text(_localization.getTranslation('settings')),
        automaticallyImplyLeading: false,
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
                  content: _localization.getTranslation('confirm_clear_history'),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFDCDE9F),
        selectedItemColor: const Color(0xFF446129),
        unselectedItemColor: const Color(0xFF92A65F),
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: _localization.getTranslation('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: _localization.getTranslation('scan history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: _localization.getTranslation('settings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.help),
            label: _localization.getTranslation('help'),
          ),
        ],
      ),
    );
  }
}
