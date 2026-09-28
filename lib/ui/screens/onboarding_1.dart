import 'package:flutter/material.dart';

class Onboarding1Screen extends StatefulWidget {
  final VoidCallback onNext;
  const Onboarding1Screen({super.key, required this.onNext});

  @override
  State<Onboarding1Screen> createState() => _Onboarding1ScreenState();
}

class _Onboarding1ScreenState extends State<Onboarding1Screen> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _floatAnimation = Tween<Offset>(begin: const Offset(0, -0.05), end: const Offset(0, 0.05))
        .animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5, 
              child: SlideTransition(
                position: _floatAnimation,
                child: Image.asset('assets/images/onboarding_1.png'),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Breathe the Future', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  SizedBox(height: 16),
                  Text('LIVERA transforms CO2 into fresh O2 using advanced microalgae technology.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF8B8F93), height: 1.5)),
                ],
              ),
            ),
            _buildDots(0),
            const SizedBox(height: 32),
            _buildPrimaryButton('Next', widget.onNext),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A27), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))));
  }

  Widget _buildDots(int activeIndex) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), width: index == activeIndex ? 24 : 8, height: 8, decoration: BoxDecoration(color: index == activeIndex ? const Color(0xFF2D5A27) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)))));
  }
}