import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n.dart';

class HelpScreen extends StatelessWidget {
  final AppLocalizations localizations;

  const HelpScreen({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    const Color greenColor = Color(0xFF059212);
    const Color grayColor = Color(0xFF787878);

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
          localizations.getTranslation('help'), // Removed .toUpperCase()
          style: TextStyle(color: greenColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  localizations
                      .getTranslation('how_to_use'), // Removed .toUpperCase()
                  style: TextStyle(color: grayColor),
                ),
                trailing: Icon(Icons.book, color: greenColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HowToUseScreen(localizations: localizations),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32.0),
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
                  localizations
                      .getTranslation('faqs'), // Removed .toUpperCase()
                  style: TextStyle(color: grayColor),
                ),
                trailing: Icon(Icons.book, color: greenColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FAQsScreen(localizations: localizations),
                    ),
                  );
                },
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

class HowToUseScreen extends StatelessWidget {
  final AppLocalizations localizations;

  const HowToUseScreen({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    const Color greenColor = Color(0xFF059212);
    const Color grayColor = Color(0xFF787878);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: greenColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          localizations.getTranslation('how_to_use'),
          style: TextStyle(color: greenColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: greenColor),
              title: Text(
                localizations.getTranslation('scan now'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('scan_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
            ListTile(
              leading: Icon(Icons.image, color: greenColor),
              title: Text(
                localizations.getTranslation('upload image'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('upload_image_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history, color: greenColor),
              title: Text(
                localizations.getTranslation('scan history'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('history_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: greenColor),
              title: Text(
                localizations.getTranslation('settings'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('settings_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: greenColor),
              title: Text(
                localizations.getTranslation('help'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('help_description'),
                style: TextStyle(color: grayColor),
              ),
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
    const Color greenColor = Color(0xFF059212);
    const Color grayColor = Color(0xFF787878);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: greenColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          localizations.getTranslation('faqs'),
          style: TextStyle(color: greenColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text(
                localizations.getTranslation('faq1_title'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('faq1_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                localizations.getTranslation('faq2_title'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('faq2_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                localizations.getTranslation('faq3_title'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('faq3_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                localizations.getTranslation('faq4_title'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('faq4_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                localizations.getTranslation('faq6_title'),
                style: TextStyle(color: grayColor),
              ),
              subtitle: Text(
                localizations.getTranslation('faq6_description'),
                style: TextStyle(color: grayColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
