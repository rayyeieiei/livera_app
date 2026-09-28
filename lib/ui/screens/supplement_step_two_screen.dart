import 'package:flutter/material.dart';
import 'supplement_step_three_screen.dart'; 
import 'package:easy_localization/easy_localization.dart';

class SupplementStepTwoScreen extends StatelessWidget {
  const SupplementStepTwoScreen({super.key});

  // --- PALETTE WARNA LIVERA SINKRON ---
  static const Color brandGreen = Color(0xFF22C55E); 
  static const Color brandGreenLight = Color(0xFFECFDF5); 
  static const Color textDark = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);

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
                // PENTING: Padding bawah biar konten gak tenggelam di balik tombol floating
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 160), 
                child: Column(
                  children: [
                    // AREA GAMBAR REACTOR DRAIN
                    _buildImageArea(),
                    const SizedBox(height: 32),
                    // KARTU INSTRUKSI
                    _buildInstructionCard (context),
                    const SizedBox(height: 20),
                    // TIPS TAMBAHAN
                    _buildProTip(),
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

  // --- WIDGET: HEADER DENGAN PROGRESS 50% ---
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
                'prep_step_header'.tr(args: ['2', '4' ,'drain_step_label'.tr()]),
                style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                height: 6,
                width: MediaQuery.of(context).size.width * 0.5, 
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET: AREA GAMBAR ---
  Widget _buildImageArea() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: brandGreenLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/reactor_drain.webp', 
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.waves_rounded, size: 60, color: brandGreen);
          },
        ),
      ),
    );
  }

  // --- WIDGET: INSTRUCTION CARD ---
  Widget _buildInstructionCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color:  isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'drain_title'.tr(),
            style: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'drain_desc'.tr(),
            style: TextStyle(color: Color(0xFF1F2937), fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: PRO TIP ---
  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brandGreenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFF059669), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Drain slowly to maintain algae quality and prevent contamination.',
                  style: TextStyle(color: Color(0xFF065F46), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: ACTION BUTTONS (FLOATING LOGIC) ---
  Widget _buildActionButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // NEXT STEP
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplementStepThreeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
            child:  Text(
              'prep_btn_next'.tr(),
              style: TextStyle(color:  isDark ? Color(0xFF1E1E1E) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // CANCEL
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context)..pop()..pop();
            },
            style: OutlinedButton.styleFrom(
              backgroundColor:  isDark ? Color(0xFF1E1E1E) : Colors.white,
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              'prep_btn_cancel'.tr(),
              style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}