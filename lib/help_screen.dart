import 'package:flutter/material.dart';
import 'l10n.dart';

class HelpScreen extends StatelessWidget {
  final AppLocalizations localizations;

  const HelpScreen({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context), // ✅ Match Camera Screen
      appBar: AppBar(
        title: Text(localizations.getTranslation('help')),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HowToUseScreen(localizations: localizations),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: ListTile(
                  title: Text(localizations.getTranslation('how_to_use')),
                  trailing: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FAQsScreen(localizations: localizations),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: ListTile(
                  title: Text(localizations.getTranslation('faqs')),
                  trailing: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **📌 Navigation Drawer (Same as Camera Screen)**
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("FreshEval"),
            accountEmail: Text("Scan and evaluate freshness"),
            decoration: BoxDecoration(color: Colors.green),
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
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help"),
            onTap: () {
              Navigator.pop(context); // Stay on this page
            },
          ),
        ],
      ),
    );
  }
}

class HowToUseScreen extends StatelessWidget {
  final AppLocalizations localizations;

  const HowToUseScreen({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.getTranslation('how_to_use')),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: Text(localizations.getTranslation('scan now')),
              subtitle: Text(localizations.getTranslation('scan_description')),
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: Text(localizations.getTranslation('upload image')),
              subtitle: Text(
                  localizations.getTranslation('upload_image_description')),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: Text(localizations.getTranslation('scan history')),
              subtitle:
                  Text(localizations.getTranslation('history_description')),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: Text(localizations.getTranslation('settings')),
              subtitle:
                  Text(localizations.getTranslation('settings_description')),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.red),
              title: Text(localizations.getTranslation('help')),
              subtitle: Text(localizations.getTranslation('help_description')),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQsScreen extends StatelessWidget {
  final AppLocalizations localizations;

  const FAQsScreen({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.getTranslation('faqs')),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text(localizations.getTranslation('faq1_title')),
              subtitle: Text(localizations.getTranslation('faq1_description')),
            ),
            const Divider(),
            ListTile(
              title: Text(localizations.getTranslation('faq2_title')),
              subtitle: Text(localizations.getTranslation('faq2_description')),
            ),
            const Divider(),
            ListTile(
              title: Text(localizations.getTranslation('faq3_title')),
              subtitle: Text(localizations.getTranslation('faq3_description')),
            ),
            const Divider(),
            ListTile(
              title: Text(localizations.getTranslation('faq4_title')),
              subtitle: Text(localizations.getTranslation('faq4_description')),
            ),
            const Divider(),
            ListTile(
              title: Text(localizations.getTranslation('faq6_title')),
              subtitle: Text(localizations.getTranslation('faq6_description')),
            ),
          ],
        ),
      ),
    );
  }
}
