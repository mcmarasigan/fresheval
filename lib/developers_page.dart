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
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.getTranslation('developers_title')),
        backgroundColor: const Color(0xFF00BFA6),
        elevation: 0,
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
                  color: const Color(0xFF00BFA6),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
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
                        'Clarissa serves as the Main Programmer for FreshEval, orchestrating the core functionality and developed the robust logic that powers the camera, image processing, and data management, making FreshEval a reliable tool for freshness evaluation.',
                        'assets/img/Marasigan.jpg',
                        'qmcmarasigan@tip.edu.ph.com',
                      ),
                      _buildTeamMember(
                        context,
                        localizations.getTranslation('member2_name'),
                        localizations.getTranslation('member2_role'),
                        'Vhon is an AI expert and the Model Trainer behind the cutting-edge freshness detection of the application',
                        'assets/img/Agbayani.jpg',
                        'qvjgagbayani@tip.edu.ph',
                      ),
                      _buildTeamMember(
                        context,
                        localizations.getTranslation('member3_name'),
                        localizations.getTranslation('member3_role'),
                        'Krysteen is a skilled Front End Developer with a passion for crafting responsive and visually appealing interfaces',
                        'assets/img/Belen.jpg',
                        'qkcrbelen@tip.edu.ph.com',
                      ),
                      _buildTeamMember(
                        context,
                        localizations.getTranslation('member4_name'),
                        localizations.getTranslation('member4_role'),
                        'Clark designs intuitive user interfaces and ensures a seamless user experience for FreshEval.',
                        'assets/img/Limson.jpg',
                        'qccflimson@tip.edu.ph.com',
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
                  color: const Color(0xFF00BFA6),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF009688)),
                title: Text(localizations.getTranslation('email_label')),
                subtitle: const Text('fresheval@xai.com'),
              ),
              ListTile(
                leading: const Icon(Icons.web, color: Color(0xFF009688)),
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
            const Icon(Icons.person, color: Color(0xFF009688), size: 20),
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
              Navigator.pushReplacementNamed(context, '/camera');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Scan History"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/help');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("Developers"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/developers');
            },
          ),
        ],
      ),
    );
  }
}

