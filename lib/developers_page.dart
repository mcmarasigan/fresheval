// developers_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n.dart';
import 'developer_detail_page.dart';

class DevelopersPage extends StatelessWidget {
  final AppLocalizations localizations;

  const DevelopersPage({super.key, required this.localizations});

  @override
  Widget build(BuildContext context) {
    const Color greenColor = Color(0xFF059212);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.getTranslation('developers_title'),
        style: TextStyle(color: greenColor),),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      ),
      drawer: _buildDrawer(context), 
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.getTranslation('about_developers'),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: greenColor,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: greenColor, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.getTranslation('developers_description'),
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.getTranslation('team_members'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTeamMember(
                        context,
                        localizations.getTranslation('member1_name'),
                        localizations.getTranslation('member1_role'),
                        localizations.getTranslation('member1_about'),                       
                        'assets/img/Marasigan.jpg',
                        'qmcmarasigan@tip.edu.ph',
                      ),
                      _buildTeamMember(
                        context,
                        localizations.getTranslation('member2_name'),
                        localizations.getTranslation('member2_role'),
                        localizations.getTranslation('member2_about'),
                        'assets/img/Agbayani.jpg',
                        'qvjgagbayani@tip.edu.ph',
                      ),
                      _buildTeamMember(
                        context,
                        localizations.getTranslation('member3_name'),
                        localizations.getTranslation('member3_role'),
                        localizations.getTranslation('member3_about'),
                        'assets/img/Belen.jpg',
                        'qkcrbelen@tip.edu.ph',
                      ),
                      _buildTeamMember(
                        context,
                        localizations.getTranslation('member4_name'),
                        localizations.getTranslation('member4_role'),
                        localizations.getTranslation('member4_about'),
                        'assets/img/Limson.jpg',
                        'qccflimson@tip.edu.ph',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                localizations.getTranslation('contact_us'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: greenColor,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.email, color: greenColor),
                title: Text(localizations.getTranslation('email_label')),
                subtitle: const Text('fresheval@xai.com'),
              ),
              ListTile(
                leading: const Icon(Icons.web, color: greenColor),
                title: Text(localizations.getTranslation('website_label')),
                subtitle: const Text('www.fresheval.com'),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
    );
  }

  Widget _buildTeamMember(
    BuildContext context,
    String name,
    String role,
    String description,
    String imagePath, // New parameter
    String email, // New parameter
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeveloperDetailPage(
              name: name,
              role: role,
              description: description,
              imagePath: imagePath,
              email: email,
              localizations: localizations,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF059212), size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                Text(
                  role,
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildDrawer(BuildContext context) {
    const Color selectedColor = Color(0xFF059212);
    const Color unselectedColor = Color(0xFF787878);
    const Color greenColor = Color(0xFF059212);

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
                    localizations.getTranslation('camera'),
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
                    localizations.getTranslation('scan history'),
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
                    localizations.getTranslation('settings'),
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
                    localizations.getTranslation('help'),
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
                    localizations.getTranslation('developers'),
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

