import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; 
import 'package:easy_localization/easy_localization.dart';

class SupplementStepFourScreen extends StatelessWidget {
  const SupplementStepFourScreen({super.key});

  // --- PALETTE WARNA LIVERA SINKRON ---
  static const Color brandGreen = Color(0xFF22C55E); // Ijo Muda Lu
  static const Color textDark = Color(0xFF111827);    // Midnight Black
  static const Color textGrey = Color(0xFF6B7280);    // Grey Text
  static const Color bgGrey = Color(0xFFF9FAFB);     // Background

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 1. --- BODY UTAMA (KONTEN SCROLL) ---
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // PENTING: Padding bawah 160 biar konten terakhir gak ketutup tombol floating
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 160), 
                child: Column(
                  children: [
                    // AREA GAMBAR STORAGE & ENJOY
                    _buildImageArea(),
                    const SizedBox(height: 40),
                    // KARTU INSTRUKSI FINAL
                    _buildInfoCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 2. --- ACTION BUTTONS (MELAYANG DI BAWAH) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildActionButtons(context),
      ),
    );
  }

  // --- WIDGET: HEADER & PROGRESS BAR 100% ---
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
              Text(
               'prep_step_header'.tr(args: ['4', '4', 'stor_step_label'.tr()]),
                style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
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

  // --- WIDGET: AREA GAMBAR ---
  Widget _buildImageArea() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/storage_enjoy.webp',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.storage_rounded, size: 60, color: brandGreen);
          },
        ),
      ),
    );
  }

  // --- WIDGET: INFO CARD ---
  Widget _buildInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color:  isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'stor_title'.tr(),
            style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'stor_desc'.tr(),
            style: TextStyle(color: textGrey, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: ACTION BUTTONS (FLOATING) ---
  Widget _buildActionButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min, // WAJIB biar gak narik ke atas
      children: [
        // TOMBOL FINISH (COMPLETE HARVEST)
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(serialNumber: ''), 
                ),
                (route) => false,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Harvesting Completed! Your data is safe."),
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
            child:  Text(
              'stor_bnt_complete'.tr(),
              style: TextStyle(color:  isDark ? Color(0xFF1E1E1E) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              backgroundColor:  isDark ? Color(0xFF1E1E1E) : Colors.white,
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              'stor_btn_back'.tr(),
              style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}