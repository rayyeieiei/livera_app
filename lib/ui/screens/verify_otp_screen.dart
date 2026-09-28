import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'setup_profile_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  List<TextEditingController> controllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  
  bool canResendEmail = true;
  int _secondsRemaining = 0;
  Timer? resendTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Gak perlu kirim pas awal masuk karena udah dikirim pas Register jir
  }

  void startResendTimer() {
    setState(() {
      canResendEmail = false;
      _secondsRemaining = 60; 
    });

    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          canResendEmail = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

Future<void> _resendOtp() async {
  // 1. Cek dulu, kalo masih cooldown atau lagi loading, jangan kasih lewat!
  if (!canResendEmail || _isLoading) return;

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse('https://livera.mataramteachingfactory.store/api/resend-otp'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": widget.email}),
    );

    if (response.statusCode == 200) {
      _showSnackBar("OTP baru meluncur! Cek email kamu 📧", const Color(0xFF2D5A27));
      
      // 🔥 2. MULAI COOLDOWN CUMA KALO SUKSES
      startResendTimer(); 
      
      for (var controller in controllers) { controller.clear(); }
      focusNodes[0].requestFocus();
    } else {
      // Kalo gagal (misal server lagi sibuk), jangan mulai timer biar bisa coba lagi
      _showSnackBar("Gagal kirim, coba lagi sedetik lagi.", Colors.redAccent);
    }
  } catch (e) {
    _showSnackBar("Koneksi Error: $e", Colors.redAccent);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  // --- API: VERIFIKASI KE BACKEND GO ---
  Future<void> _verifyOtp() async {
    String otpCode = controllers.map((c) => c.text).join();

    if (otpCode.length < 6) {
      _showSnackBar("Isi 6 digit kodenya dulu ya!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/verify-account'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "code": otpCode,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Verifikasi Berhasil! 🚀", const Color(0xFF2D5A27));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SetupProfileScreen()),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(data['error'] ?? "Kode salah/expired!", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Server pingsan: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5A27).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.vpn_key_rounded, size: 80, color: Color(0xFF2D5A27)),
              ),
              const SizedBox(height: 32),
              const Text(
                "Verifikasi Akun 🔑",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0A4D41)),
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
                  children: [
                    const TextSpan(text: "Kami telah mengirim kode OTP ke email:\n"),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOtpField(index)),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A27),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Verifikasi Sekarang", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum dapet kode? ", style: TextStyle(color: Colors.grey)),
                      TextButton(
                    onPressed: (canResendEmail && !_isLoading) ? _resendOtp : null, // Kalo mati, onPressed = null
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2D5A27),
                      disabledForegroundColor: Colors.grey, // Warna pas lagi cooldown
                    ),
                    child: Text(
                      canResendEmail 
                          ? "Kirim Ulang" 
                          : "Tunggu ${_secondsRemaining}s", // Munculin detik sisa
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 48, // 🔥 Lebarin dikit biar lega bray
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        // 🔥 Tambahin color: Colors.black biar pasti kelihatan terang!
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black), 
        decoration: InputDecoration(
          counterText: "",
          // 🔥 INI OBATNYA BRAY! Timpa padding bawaannya biar angkanya bisa napas di tengah!
          contentPadding: const EdgeInsets.symmetric(vertical: 14), 
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 2)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}