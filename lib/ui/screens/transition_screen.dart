import 'dart:async';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class TransitionOneScreen extends StatefulWidget {
  const TransitionOneScreen({super.key});

  @override
  State<TransitionOneScreen> createState() => _TransitionOneScreenState();
}

class _TransitionOneScreenState extends State<TransitionOneScreen> {
  int _step = 1;

  @override
  void initState() {
    super.initState();
    _runAnimation();
  }

  void _runAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Step 1: Putih
    
    setState(() => _step = 2); // Step 2: Hijau Sage
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _step = 3); // Step 3: Logo Besar Nongol di Tengah
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() => _step = 4); // Step 4: Logo Mengecil & Geser ke Kanan
    // Kita kasih delay dikit sebelum tulisan muncul biar gak barengan banget
    await Future.delayed(const Duration(milliseconds: 400));
    
    setState(() => _step = 5); // Step 5: Tulisan "LIVERA" Fade In
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // --- KALIBRASI POSISI (Biar Presisi di 375x827) ---
    const double finalLogoSize = 60.0;
    const double initialLogoSize = 180.0;
    const double textWidth = 180.0;
    const double spacing = 12.0;
    const double totalGroupWidth = textWidth + spacing + finalLogoSize;

    // Titik awal grup agar center horizontal
    final double groupStartX = (size.width - totalGroupWidth) / 2;

    // Posisi Logo
    double logoW = _step <= 3 ? initialLogoSize : finalLogoSize;
    double logoLeft = _step <= 3 
        ? (size.width / 2 - initialLogoSize / 2) // Tengah banget di awal
        : (groupStartX + textWidth + spacing);   // Di kanan teks saat akhir
    
    double logoTop = (size.height / 2 - logoW / 2);

    // Posisi Tulisan
    double textLeft = groupStartX;
    double textTop = (size.height / 2 - 22); // Center vertical (adjust dikit biar sejajar logo)

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BACKGROUND HIJAU (TRANSITION 2)
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: size.width,
            height: size.height,
            color: _step == 2 ? const Color(0xFF82A881) : Colors.transparent,
          ),

          // 2. TULISAN "LIVERA" (Muncul belakangan di step 5)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            left: textLeft,
            top: textTop,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _step >= 5 ? 1.0 : 0.0, // Muncul setelah logo geser
              child: SizedBox(
                width: textWidth,
                child: Image.asset('assets/images/logohuruf.png', fit: BoxFit.contain),
              ),
            ),
          ),

          // 3. LOGO ALGA (Mengecil & Geser)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack, // Efek kenyal pas geser biar pro
            left: logoLeft,
            top: logoTop,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _step >= 3 ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                width: logoW,
                height: logoW,
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}