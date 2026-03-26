import 'package:flutter/material.dart';
import 'package:livera_app/ui/screens/transition_screen.dart'; 


void main() { // Buka kurung
  runApp(const LiveraApp());
} // 

class LiveraApp extends StatelessWidget {
  const LiveraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Ngilangin label "Debug" di pojok kanan atas
      title: 'LIVERA',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true, // Biar tampilan modern ala Android terbaru
      ),
      // Di sini pintu masuknya! Lu arahin ke TransitionScreen dulu
      home: TransitionOneScreen(), 
    );
  }
}