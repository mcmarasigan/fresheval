import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _photoTips = [
    {
      'title': 'Clean Your Camera',
      'description':
          'Wipe your camera lens with a soft cloth to remove smudges and dust for clearer photos.',
      'image': 'assets/img/clean_cam.png',
    },
    {
      'title': 'Good Lighting',
      'description':
          'Take photos in well-lit conditions. Avoid direct sunlight or dark shadows.',
      'image': 'assets/img/good_lighting.png',
    },
    {
      'title': 'Steady & Clear',
      'description':
          'Hold your phone steady to avoid blurry images. Tap to focus on the vegetables.',
      'image': 'assets/img/steady_clear.png',
    },
    {
      'title': 'Full View',
      'description':
          'Capture the entire vegetable in the frame. Avoid cutting off parts of it.',
      'image': 'assets/img/full_view.png',
    },
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    Navigator.of(context).pushReplacementNamed('/camera');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _photoTips.length + 1, // +1 for welcome page
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const WelcomePage();
                  } else {
                    final tipIndex = index - 1;
                    return PhotoTipPage(
                      title: _photoTips[tipIndex]['title']!,
                      description: _photoTips[tipIndex]['description']!,
                      image: _photoTips[tipIndex]['image']!,
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _photoTips.length + 1,
                      (index) => _buildDot(index, context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _photoTips.length) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _photoTips.length
                          ? 'Get Started'
                          : 'Next',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                  if (_currentPage != _photoTips.length)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/img/logo.png', // Replace with your logo filename
            width: 300, // Adjust size as needed
            height: 300,
            fit: BoxFit.contain, // Ensures proper scaling
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to FreshEval!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Scan your veggies and detect freshness instantly\n\nGet smart storage tips & recommendations',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PhotoTipPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const PhotoTipPage({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            width: 300, // Adjust size as needed
            height: 300,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
