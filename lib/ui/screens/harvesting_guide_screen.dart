import 'package:flutter/material.dart';
import 'supplement_step_screen.dart'; 
import 'fertilizer_step_one_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class HarvestingGuideScreen extends StatefulWidget {
  const HarvestingGuideScreen({super.key});

  @override
  State<HarvestingGuideScreen> createState() => _HarvestingGuideScreenState();
}

class _HarvestingGuideScreenState extends State<HarvestingGuideScreen> {
  int _selectedGuideIndex = 0; 

  static const Color brandGreen = Color(0xFF22C55E); 

  @override
  Widget build(BuildContext context) {
    // 1. Ambil status dark mode di sini
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. TOP NAV ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularIconButton(Icons.arrow_back, () => Navigator.pop(context), isDark),
                  _buildCircularIconButton(Icons.more_vert, () => print("Menu"), isDark),
                ],
              ),

              const SizedBox(height: 32),

              // --- 2. HEADER ---
               Center(
                child: Text(
                  'harv_title'.tr(),
                  style: TextStyle(color: brandGreen, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'harv_subtitle'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280), 
                    fontSize: 14
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // --- 3. CHOICE AREA ---
              _buildGuideCard(
                index: 0,
                title: 'harv_card1_title'.tr(),
                desc: 'harv_card1_desc'.tr(),
                icon: Icons.science_outlined,
                isDark: isDark, // OPER NILAINYA DI SINI JIR!
              ),

              const SizedBox(height: 16),

              _buildGuideCard(
                index: 1,
                title: 'harv_card2_title'.tr(),
                desc: 'harv_card2_desc'.tr(),
                icon: Icons.spa_outlined,
                isDark: isDark,
              ),

              const SizedBox(height: 80),

              // --- 4. START BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedGuideIndex == 0) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SupplementStepScreen()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FertilizerStepOneScreen()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen, 
                    // Teks tombol: item pekat kalo di light, tetep item/putih sesuai selera
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'harv_btn_start'.tr(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER: GUIDE CARD ---
  Widget _buildGuideCard({
    required int index,
    required String title,
    required String desc,
    required IconData icon,
    required bool isDark, 
  }) {
    bool isSelected = _selectedGuideIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedGuideIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          // LOGIC WARNA CARD SAKTI:
          color: isSelected 
              ? brandGreen 
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? brandGreen 
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          boxShadow: [
            if (!isDark) // Shadow cuma muncul di mode terang biar gak kotor
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2) 
                    : brandGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : brandGreen, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      // TEXT SAKTI: Kalo kepilih putih, kalo enggak ngikutin tema
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? Colors.white : const Color(0xFF111827)),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white.withOpacity(0.9) 
                          : (isDark ? Colors.white60 : const Color(0xFF4B5563)),
                      fontSize: 14,
                      height: 1.5,
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

  // --- HELPER: CIRCULAR BUTTON ---
  Widget _buildCircularIconButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
        ),
        child: Icon(icon, color: isDark ? Colors.white : const Color(0xFF111827), size: 20),
      ),
    );
  }
}