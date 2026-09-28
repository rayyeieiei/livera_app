import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'onboarding_wrapper.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../../main.dart'; // Tetap jagain path import UserProvider lu jir[cite: 2]

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _step = 0; 

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Langkah 1: Jeda layar putih awal[cite: 2]
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _step = 1); //[cite: 2]

    // Langkah 2: Masuk ke transisi warna hijau[cite: 2]
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _step = 2); //[cite: 2]

    // Langkah 3: Berubah jadi Putih + Munculin Logo Full HD
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _step = 3); //[cite: 2]

    // Langkah 4: Jeda sebentar biar user liat logonya, lalu gas Smart Routing[cite: 2]
    await Future.delayed(const Duration(milliseconds: 1500)); //[cite: 2]

    final prefs = await SharedPreferences.getInstance(); //[cite: 2]
    final bool onboardingDone = prefs.getBool('onboarding_done') ?? false; //[cite: 2]
    final String? token = prefs.getString('jwt_token'); //[cite: 2]

    if (!mounted) return; //[cite: 2]

    if (token != null && token.isNotEmpty) { //[cite: 2]
      final userProvider = Provider.of<UserProvider>(context, listen: false); //[cite: 2]
      userProvider.loadSavedData(prefs); //[cite: 2]
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen(serialNumber: userProvider.serialNumber))); //[cite: 2]
    } else if (onboardingDone) { //[cite: 2]
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); //[cite: 2]
    } else { //[cite: 2]
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingWrapper())); //[cite: 2]
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Background ijo, sisanya putih bersih bray[cite: 2]
    final bgColor = _step == 1 ? const Color(0xFF81A282) : Colors.white; //[cite: 2]

    return Scaffold(
      backgroundColor: bgColor, //[cite: 2]
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500), // Efek transisi antar step biar smooth[cite: 2]
          child: _buildContent(), //[cite: 2]
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_step == 0 || _step == 1) { //[cite: 2]
      return const SizedBox.shrink(); // Layar kosong pas transisi awal[cite: 2]
    } else if (_step == 2) {
      // 🔥 STEP 2: Munculin ikon daun tunggal yang enteng dari folder icons (image_be89e2.png)
      return Image.asset(
        'assets/icons/app_logo.png', 
        height: 140, 
        key: const ValueKey('just_icon')
      );
    } else {
      // 🔥 STEP 3 FINAL: Langsung panggil file satu paket full lu tanpa text widget tambahan bray!
      // Path-nya ke folder images sesuai foto lu (image_be89ac.png)
      return Image.asset(
        'assets/images/logo_livera_full.webp', 
        height: 140, // Tingginya disesuaiin biar pas dan kelihatan mewah di layar
        fit: BoxFit.contain,
        key: const ValueKey('full_combined_logo')
      );
    }
  }
}