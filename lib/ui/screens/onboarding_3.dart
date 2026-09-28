import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class Onboarding3Screen extends StatefulWidget {
  final VoidCallback onBack;
  const Onboarding3Screen({super.key, required this.onBack});

  @override
  State<Onboarding3Screen> createState() => _Onboarding3ScreenState();
}

class _Onboarding3ScreenState extends State<Onboarding3Screen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // 🔥 LOGIC PENYIMPANAN DATA BIAR GAK ONBOARDING LAGI BESOKNYA
  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true); 
    
    if (mounted) {
      // 🚀 Sukses! Lempar ke layarnya Rastiar (LoginScreen)
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5, 
              child: ScaleTransition(scale: _pulseAnimation, child: Image.asset('assets/images/onboarding_3.png')),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Total Wellness', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  SizedBox(height: 16),
                  Text('Harvest nutrient-rich biomass and learn via our Algae Academy.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF8B8F93), height: 1.5)),
                ],
              ),
            ),
            _buildPrimaryButton('Get Started', _finishOnboarding), // Panggil fungsi ajaibnya
            TextButton(onPressed: widget.onBack, child: const Text('Back', style: TextStyle(color: Color(0xFF8B8F93)))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A27), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))));
  }
}