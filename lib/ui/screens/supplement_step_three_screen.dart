import 'package:flutter/material.dart';
import 'supplement_step_four_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class SupplementStepThreeScreen extends StatelessWidget {
  const SupplementStepThreeScreen({super.key});

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
                // PENTING: Padding bawah 160 biar konten terakhir gak ketutup tombol melayang
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 160), 
                child: Column(
                  children: [
                    _buildImageArea(),
                    const SizedBox(height: 40),
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

  // --- WIDGET: HEADER & PROGRESS BAR 75% ---
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
                'prep_step_header'.tr(args: ['3', '4', 'filt_step_label'.tr()]), // "Step 3 of 4" dengan terjemahan
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
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                height: 6,
                width: MediaQuery.of(context).size.width * 0.75, // 75% Progress
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
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/filtering_process.webp',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.filter_alt_outlined, size: 60, color: brandGreen);
          },
        ),
      ),
    );
  }

  // --- WIDGET: INFO CARD ---
  Widget _buildInfoCard(BuildContext context  ) {
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
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'filt_title'.tr(), 
            style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'filt_desc'.tr(),
            style: TextStyle(color: textGrey, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: ACTION BUTTONS ---
  Widget _buildActionButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TOMBOL NEXT STEP
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplementStepFourScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4, // Kasih shadow biar efek floating mantap
            ),
            child:  Text(
              'prep_btn_next'.tr(), 
              style: TextStyle(color:  isDark ? Color(0xFF1E1E1E) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // TOMBOL CANCEL
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton(
            onPressed: () {
              // Balik 3x sampe ke menu selection
              Navigator.of(context)..pop()..pop()..pop();
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              'prep_btn_cancel'.tr() ,
              style: TextStyle(color: Color(0xFF374151), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}