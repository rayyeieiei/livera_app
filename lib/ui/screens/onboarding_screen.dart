import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Wajib import ini buat baca file .svg
import 'login_qr_screen.dart'; // Import the LoginScreen
import 'package:easy_localization/easy_localization.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

 Future<void> _finishOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_done', true); 
  
  if (mounted) {
    // COBA ARAHIN KE LOGINSCREEN DULU JIR, JANGAN KE QR DULU
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginQrScreen()),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    // Kita pisah datanya. Ada title, deskripsi, dan widget khusus untuk gambarnya.
    final List<Map<String, dynamic>> onboardingData = [
      {
        "title": "Breathe the Future",
        "desc": "LIVERA transforms CO2 into fresh O2 using advanced microalgae technology.",
        "graphic": Image.asset('assets/images/onboarding_1.png', height: 300),
      },
      {
        "title": "Intelligent Ecosystem",
        "desc": "Monitor air quality, nutrient levels, and algae health in real-time.",
        "graphic": _buildOnboarding2Mockup(), // Panggil fungsi pembuat UI Onboarding 2
      },
      {
        "title": "Total Wellness",
        "desc": "Harvest nutrient-rich biomass and learn via our Algae Academy.",
        "graphic": Image.asset('assets/images/onboarding_3.png', height: 300),
      }
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // Render graphic (Bisa PNG, bisa Mockup UI)
                        onboardingData[index]["graphic"],
                        const Spacer(),
                        Text(
                          onboardingData[index]["title"],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onboardingData[index]["desc"],
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indikator Titik & Tombol Bawah
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 6,
                        width: _currentPage == index ? 20 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? const Color(0xFF2D5427) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== WIDGET KHUSUS ONBOARDING 2 ====
  // Karena onboarding 2 pakai SVG dan bentuknya UI Dashboard, kita rakit di sini
  Widget _buildOnboarding2Mockup() {
    return Container(
      height: 300,
      width: 220, // Ukuran lebar kotak mockup
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          // Header Mockup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("LIVERA Dashboard", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              SvgPicture.asset('assets/icons/notification_grey.svg', width: 14),
            ],
          ),
          const Spacer(),
          // Lingkaran Progress di Tengah
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: 0.87, // Nilai 87%
                    strokeWidth: 8,
                    color: Color(0xFF2196F3), // Sesuaikan warna hijaunya jika perlu
                    backgroundColor: Colors.white,
                  ),
                ),
                Text("87%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text("Growth Efficiency", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
          const Spacer(),
          // Deretan Icon SVG di bawah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconBox('assets/icons/air_blue.svg', Colors.blue.shade50),
              _buildIconBox('assets/icons/water_nutrient_green.svg', Colors.green.shade50),
              _buildIconBox('assets/icons/pulse_heartbeat_orange.svg', Colors.orange.shade50),
            ],
          )
        ],
      ),
    );
  }


Widget _buildIconBox(String assetPath, Color bgColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // Kalo Dark Mode, bikin background icon-nya agak redup biar gak kontras banget
        color: isDark ? bgColor.withOpacity(0.2) : bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.asset(
        assetPath, 
        width: 20, height: 20,
        // Kalo Dark Mode, kita paksa warna SVG-nya nyesuain (kalo satu warna)
        colorFilter: isDark ? ColorFilter.mode(bgColor, BlendMode.srcIn) : null,
      ),
    );
  }

  // --- WIDGET 2: BOTTOM BUTTONS (LOGIC SAKTI) ---
  Widget _buildBottomButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color brandGreen = Color(0xFF2D5427);

    if (_currentPage == 0) {
      // --- PAGE 0: NEXT (OUTLINED) ---
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.ease),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isDark ? brandGreen.withOpacity(0.8) : brandGreen),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("onb_next".tr(), 
            style: TextStyle(
              color: isDark ? Colors.white : brandGreen, 
              fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ),
      );
    } else if (_currentPage == 1) {
      // --- PAGE 1: BACK & NEXT (TEXT BUTTONS) ---
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300), curve: Curves.ease),
            child: Text("onb_back".tr(), 
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 16)),
          ),
          TextButton(
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300), curve: Curves.ease),
            child:  Text("onb_next".tr(),
              style: TextStyle(color: brandGreen, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else {
      // --- PAGE 2: GET STARTED (ELEVATED) ---
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _finishOnboarding, // <--- PANGGIL FUNGSI SIMPEN DATA
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            foregroundColor: Colors.white, // Warna teks tombol tetep putih biar kontras
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text("Get Started", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }

    }
  }
