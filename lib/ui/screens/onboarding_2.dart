import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Onboarding2Screen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const Onboarding2Screen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFF2F4F6), Colors.white])),
                child: Center(child: _buildDashboardMockupCard()), 
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Intelligent\nEcosystem', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF333333), height: 1.2, fontFamily: 'Inter')),
                    SizedBox(height: 16),
                    Text('Monitor air quality, nutrient levels, and algae health in real-time.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF8B8F93), height: 1.5, fontFamily: 'Inter')),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: onBack, child: const Text('Back', style: TextStyle(fontSize: 16, color: Color(0xFF8B8F93)))),
                  _buildDots(1),
                  TextButton(onPressed: onNext, child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D5A27)))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardMockupCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 260, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 40, offset: Offset(0, 10))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('LIVERA Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF222222))), SvgPicture.asset('assets/icons/notification_grey.svg', width: 16)]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24), width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFE6F7EC), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SizedBox(
                    width: 90, height: 90,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 0.87), duration: const Duration(milliseconds: 1500), curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Stack(fit: StackFit.expand, children: [CircularProgressIndicator(value: value, strokeWidth: 8, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)), strokeCap: StrokeCap.round), Center(child: Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF222222))))]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Growth Efficiency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F3F1F))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildIconBox('assets/icons/air_blue.svg', const Color(0xFFEFF6FF)), _buildIconBox('assets/icons/water_nutrient_green.svg', const Color(0xFFF0FDF4)), _buildIconBox('assets/icons/pulse_heartbeat_orange.svg', const Color(0xFFFFF7ED))]),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(String svgPath, Color bgColor) => Container(width: 52, height: 52, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Center(child: SvgPicture.asset(svgPath, width: 24, height: 24)));
  Widget _buildDots(int activeIndex) => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), width: index == activeIndex ? 24 : 8, height: 8, decoration: BoxDecoration(color: index == activeIndex ? const Color(0xFF2D5A27) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)))));
}