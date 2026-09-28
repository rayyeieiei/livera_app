import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_qr_screen.dart';    
import 'onboarding_wrapper.dart';
import 'dashboard_screen.dart'; // Import Dashboard buat auto-login

class TransitionScreen extends StatefulWidget {
 const TransitionScreen({super.key});

 @override
 State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen> {
 int _step = 0; 

 @override
 void initState() {
  super.initState();
  _playAnimation();
 }

 Future<void> _playAnimation() async {
  // Step 0: Initial (Loading internal)
  await Future.delayed(const Duration(milliseconds: 600));
  
  // Step 1: Transisi ke Layar Sage Green (Identitas Livera)
  if (mounted) setState(() => _step = 1);
  await Future.delayed(const Duration(milliseconds: 1000));
  
  // Step 2: Balik ke Putih + Munculin Logo Daun
  if (mounted) setState(() => _step = 2);
  await Future.delayed(const Duration(milliseconds: 1200));
  
  // Step 3: Munculin Logo Full (Teks + Daun)
  if (mounted) setState(() => _step = 3);
    
  final prefs = await SharedPreferences.getInstance();
    
    // Ambil flag onboarding dan serial alat
  bool isDone = prefs.getBool('onboarding_done') ?? false;
    String? savedSerial = prefs.getString('device_serial');

    // Kasih napas buat user liat logo full
  await Future.delayed(const Duration(seconds: 2));

  if (mounted) {
      Widget nextScreen;

      if (!isDone) {
        // Kalo baru pertama kali instal banget
        nextScreen = const OnboardingWrapper();
      } else if (savedSerial != null && savedSerial.isNotEmpty) {
        nextScreen = DashboardScreen(serialNumber: savedSerial);
      } else {
        // Kalo udah onboarding tapi belum scan alat
        nextScreen = const LoginQrScreen();
      }

   Navigator.pushReplacement(
    context,
    PageRouteBuilder(
     transitionDuration: const Duration(milliseconds: 800),
     pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
     transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
     },
    ),
   );
  }
 }

 @override
 Widget build(BuildContext context) {
    // Cek Dark Mode biar pas Splash Screen gak silau kalo user lagi mode gelap
    final isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
   // Background adaptif pas Step 1 (Sage Green)
   backgroundColor: _step == 1 
          ? const Color(0xFF86A789) 
          : (isDark ? const Color(0xFF121212) : Colors.white),
   body: Center(
    child: AnimatedSwitcher(
     duration: const Duration(milliseconds: 600),
     child: _buildContent(),
    ),
   ),
  );
 }

 Widget _buildContent() {
  if (_step == 0 || _step == 1) {
   return const SizedBox(key: ValueKey('empty'));
  } 
  
  if (_step == 2) {
   return Image.asset(
    'assets/images/logo.webp', 
    width: 120, // Ukuran disesuaiin biar pas di A54
    key: const ValueKey('logo_only'),
   );
  } 
  
  if (_step == 3) {
   return Image.asset(
    'assets/images/logo_livera_full.webp', 
    width: 220, 
    key: const ValueKey('logo_full'),
   );
  }
  
  return const SizedBox();
 }
}