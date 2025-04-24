// loading_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Simulate loading delay and transition to main app
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/camera');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color greenColor = Color(0xFF059212);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Matches app background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo/Icon
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'assets/img/logo2.png', //logo without 'fresheval'
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            // App Name
            Text(
              'FreshEval',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: greenColor,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            Text(
              'Evaluating Vegetable Freshness',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.green, // Accent color
              ),
            ),
            const SizedBox(height: 30),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059212)),
            ),
          ],
        ),
      ),
    );
  }
}
