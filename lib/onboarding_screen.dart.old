import 'package:flutter/material.dart';
import 'package:fresheval/carousel_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Future<void> _completeOnboarding(BuildContext context, {required bool showTips}) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('isFirstTime', false);
  //   await prefs.setBool('showCameraTips', showTips);
  //   Navigator.of(context).pushReplacementNamed('/camera');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/img/welcome.png', 
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to FreshEval!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF059212),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Instantly check if your eggplant, tomato, or potato is fresh or rotten using AI-powered image scanning on your phone.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isFirstTime', false); {  
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => const CarouselScreen()));}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059212),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  'Get Started',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // const SizedBox(height: 16),
              // TextButton(
              //   onPressed: () => _completeOnboarding(context, showTips: false),
              //   child: Text(
              //     'Skip',
              //     style: GoogleFonts.poppins(
              //       fontSize: 14,
              //       color: Theme.of(context).colorScheme.secondary,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
