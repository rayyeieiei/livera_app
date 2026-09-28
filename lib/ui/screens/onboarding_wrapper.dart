import 'package:flutter/material.dart';
import 'onboarding_1.dart';
import 'onboarding_2.dart';
import 'onboarding_3.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final PageController _pageController = PageController();

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  void _prevPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Wajib pencet tombol Next/Back
        children: [
          Onboarding1Screen(onNext: _nextPage),
          Onboarding2Screen(onNext: _nextPage, onBack: _prevPage),
          Onboarding3Screen(onBack: _prevPage),
        ],
      ),
    );
  }
}