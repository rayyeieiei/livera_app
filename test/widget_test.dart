import 'package:flutter_test/flutter_test.dart';
import 'package:livera_app/main.dart'; // Pastikan import ini sesuai

void main() {
  testWidgets('Aplikasi Livera bisa berjalan', (WidgetTester tester) async {
    // Build aplikasi kita tanpa parameter onboardingDone
    await tester.pumpWidget(const LiveraApp()); 

    // Karena aplikasi sekarang diawali dengan TransitionScreen (Splash),
    // kita cukup memastikan widget utama berhasil dirender (tidak crash).
    expect(find.byType(LiveraApp), findsOneWidget);
  });
}