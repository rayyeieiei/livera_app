import 'package:flutter/material.dart';
import 'fertilizer_step_three_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class FertilizerStepTwoScreen extends StatelessWidget {
  const FertilizerStepTwoScreen({super.key});

  // --- PALETTE WARNA LIVERA SINKRON ---
  static const Color brandGreen = Color(0xFF22C55E); // Ijo Muda Lu
  static const Color textDark = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color bgGrey = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER & PROGRESS BAR (50%)
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // PENTING: Padding bawah 160 biar gak ketutup tombol floating
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
                child: Column(
                  children: [
                    // 2. --- ASSET GAMBAR DRAIN FERTILIZER ---
                    // Nama Asset: assets/images/fertilizer_drain.webp
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bgGrey,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Image.asset(
                        'assets/images/fertilizer_drain.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.opacity_rounded, size: 60, color: brandGreen);
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
        // Progress Bar 50%
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('prep_step_header'.tr(args: ['2', '4', 'fert_drain_label'.tr()]), style: TextStyle(color: brandGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              const Text('50%', style: TextStyle(color: brandGreen, fontSize: 12, fontWeight: FontWeight.bold)),
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
                width: MediaQuery.of(context).size.width * 0.5, // 50% Progress
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
            child:  Icon(Icons.water_drop_rounded, color: isDark ? Color(0xFF1E1E1E) : Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'fert_drain_title'.tr(),
                  style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'fert_drain_desc'.tr(),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FertilizerStepThreeScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
            child:  Text('prep_btn_next'.tr(), style: TextStyle(color: isDark ? Color(0xFF1E1E1E) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton(
            onPressed: () {
              // Balik 2x ke menu selection
              Navigator.of(context)..pop()..pop();
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text('prep_btn_cancel'.tr()  , style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}