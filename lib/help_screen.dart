import 'package:flutter/material.dart';
import 'l10n.dart';

class HelpScreen extends StatelessWidget {
  final AppLocalizations localizations;

  const HelpScreen({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.getTranslation('help')),
        backgroundColor: const Color(0xFFDCDE9F),
        elevation: 0,
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFDCDE9F),
        selectedItemColor: const Color(0xFF446129),
        unselectedItemColor: const Color(0xFF92A65F),
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, '/home');
          if (index == 1) Navigator.pushNamed(context, '/history');
          if (index == 2) Navigator.pushNamed(context, '/settings');
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: localizations.getTranslation('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: localizations.getTranslation('scan history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: localizations.getTranslation('settings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.help),
            label: localizations.getTranslation('help'),
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
        backgroundColor: const Color(0xFFDCDE9F),
        elevation: 0,
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
              subtitle:
                  Text(localizations.getTranslation('upload_image_description')),
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
        backgroundColor: const Color(0xFFDCDE9F),
        elevation: 0,
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
