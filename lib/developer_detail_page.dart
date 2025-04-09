// developer_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n.dart';

class DeveloperDetailPage extends StatelessWidget {
  final String name;
  final String role;
  final String description;
  final String imagePath; // New: Path to the developer's image
  final String email; // New: Developer's email
  final AppLocalizations localizations;

  const DeveloperDetailPage({
    super.key,
    required this.name,
    required this.role,
    required this.description,
    required this.imagePath,
    required this.email,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFF00BFA6),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.getTranslation('developer_details'),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00BFA6),
                ),
              ),
              const SizedBox(height: 16),
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
                      // Developer Image
                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            imagePath,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 120,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.getTranslation('name_label'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(name, style: GoogleFonts.poppins()),
                      const SizedBox(height: 12),
                      Text(
                        localizations.getTranslation('role_label'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(role, style: GoogleFonts.poppins()),
                      const SizedBox(height: 12),
                      Text(
                        localizations.getTranslation('about_label'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(description, style: GoogleFonts.poppins()),
                      const SizedBox(height: 12),
                      // Email Field
                      Text(
                        localizations.getTranslation('email_label'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(email, style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
    );
  }
}
