import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; 
import 'package:easy_localization/easy_localization.dart';

class FertilizerStepFourScreen extends StatelessWidget {
  const FertilizerStepFourScreen({super.key});

  // --- PALETTE WARNA LIVERA SINKRON ---
  static const Color brandGreen = Color(0xFF22C55E); // Ijo Muda Lu
  static const Color textDark = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color bgGrey = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 1. --- BODY UTAMA (KONTEN SCROLL) ---
      body: SafeArea(
        child: Column(
          children: [
            // HEADER & PROGRESS BAR (100% FULL)
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // PENTING: Padding bawah 160 biar gak ketutup tombol floating
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
                child: Column(
                  children: [
                    // 2. --- ASSET GAMBAR MENYIRAM ---
                    // Nama Asset: assets/images/fertilizer_final.webp
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Image.asset(
                        'assets/images/fertilizer_final.webp', 
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.eco, size: 80, color: brandGreen);
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 3. --- INFO CARD ---
                    _buildInfoCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ==========================================
      // ACTION BUTTONS (MELAYANG DI BAWAH)
      // ==========================================
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildActionButtons(context),
      ),
    );
  }

  // --- WIDGET: HEADER ---
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: textDark),
              ),
              const SizedBox(width: 8),
              const Text(
                'Fertilizer Guide',
                style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // Progress Bar 100%
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('prep_step_header'.tr(args: ['4', '4', 'fert_apply_label'.tr()]), style: TextStyle(color: brandGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              const Text('100%', style: TextStyle(color: brandGreen, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: brandGreen,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET: INFO CARD ---
  Widget _buildInfoCard(context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: brandGreen.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: brandGreen, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.yard_rounded, color: isDark ? Color(0xFF1E1E1E) : Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'fert_apply_title'.tr(),
                  style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'fert_apply_desc'.tr(),
                  style: TextStyle(color: textGrey, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: TOMBOL AKSI (FLOATING) ---
  Widget _buildActionButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen(serialNumber: '',)), 
                (route) => false,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Fertilizer Applied! Activity logged."),
                  backgroundColor: brandGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
            child:  Text('fert_btn_finish'.tr(), style: TextStyle(color: isDark ? Color(0xFF1E1E1E) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text('prep_btn_cancel'.tr(), style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}