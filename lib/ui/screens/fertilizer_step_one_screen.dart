import 'package:flutter/material.dart';
import 'fertilizer_step_two_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class FertilizerStepOneScreen extends StatelessWidget {
  const FertilizerStepOneScreen({super.key});

  // --- PALETTE WARNA LIVERA SINKRON ---
  static const Color brandGreen = Color(0xFF22C55E); // Ijo Muda Lu
  static const Color textDark = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color bgGrey = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // --- BODY UTAMA (SCROLLABLE) ---
      body: SafeArea(
        child: Column(
          children: [
            // 1. --- HEADER & PROGRESS BAR (25%) ---
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // PENTING: Kasih padding bawah (160) biar konten gak ketutup tombol floating
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
                child: Column(
                  children: [
                    // 2. --- ASSET GAMBAR ALAT KEBUN ---
                    // Nama Asset: assets/images/fertilizer_prep.webp
                    Container(
                      height: 260,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bgGrey,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Image.asset(
                        'assets/images/fertilizer_prep.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.handyman_outlined, size: 60, color: brandGreen);
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
      // ACTION BUTTONS (FLOATING VERSION)
      // ==========================================
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Biar gak makan seluruh layar
          children: [
            // TOMBOL NEXT
            SizedBox(
              
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FertilizerStepTwoScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 4, // Kasih shadow biar efek floating makin berasa
                  
                ),
                child: Text(
                  'prep_btn_next'.tr(),
                  style: TextStyle(color: isDark ? Color(0xFF1E1E1E) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // TOMBOL CANCEL
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
                child: Text(
                  'prep_btn_cancel'.tr(),
                  style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('prep_step_header'.tr(args: ['1', '4', 'fert_title'.tr()]), style: TextStyle(color: brandGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              const Text('25%', style: TextStyle(color: brandGreen, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              ),
              Container(
                height: 6,
                width: MediaQuery.of(context).size.width * 0.25,
                decoration: BoxDecoration(color: brandGreen, borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET: INFO CARD ---
  Widget _buildInfoCard(BuildContext context) {
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
            child:  Icon(Icons.eco, color: isDark ? Color(0xFF1E1E1E) : Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'fert_prep_title'.tr(),
                  style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'fert_prep_desc'.tr(),

                  style: TextStyle(color: textGrey, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}