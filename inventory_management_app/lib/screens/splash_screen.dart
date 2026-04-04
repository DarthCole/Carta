import 'package:flutter/material.dart';

/// displaying the carta brand splash screen on app launch.
///
/// showing an animated logo with a fade-in and elastic scale effect
/// over a navy-to-blue gradient background. automatically navigating
/// to the stores screen after a 3-second delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // driving both animations
  late Animation<double> _fadeIn; // controlling opacity from 0 to 1
  late Animation<double> _scale; // controlling size with an elastic bounce

  @override
  void initState() {
    super.initState();

    // setting up the animation controller with a 1.5-second duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // creating a fade-in animation with ease-in curve
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // creating a scale animation with elastic overshoot
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // starting the animation and scheduling navigation
    _controller.forward();
    _navigateToHome();
  }

  /// waiting 3 seconds then navigating to the stores screen,
  /// replacing the splash so the user cannot navigate back to it.
  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/stores');
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // cleaning up the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // applying a gradient background from navy to blue
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF01579B)],
          ),
        ),
        child: Center(
          // wrapping the content in fade and scale transitions
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // app icon container with translucent background
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // app title with wide letter spacing
                  const Text(
                    'CARTA',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // subtitle text
                  Text(
                    'Inventory Management',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // loading spinner indicating app initialisation
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
