import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// 🔥 Tambahin ini jir buat manggil fungsi filter angka
import 'package:flutter/services.dart'; 
import '../../main.dart'; 
import 'dashboard_screen.dart';

class PasswordInputScreen extends StatefulWidget {
  final String sn;
  final String correctPassword;

  const PasswordInputScreen({
    super.key,
    required this.sn,
    required this.correctPassword,
  });

  @override
  State<PasswordInputScreen> createState() => _PasswordInputScreenState();
}

class _PasswordInputScreenState extends State<PasswordInputScreen> {
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  // --- 🚀 LOGIC: AKTIVASI KE BACKEND GO (GIN) ---
  Future<void> _verifyAndClaim() async {
    String input = _passController.text.trim();

    // 1. Cek PIN Fisik Alat (Lokal dulu jir)
    if (input != widget.correctPassword) {
      _showError('PIN salah! Cek stiker di bawah alat LIVERA kamu.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Ambil Token JWT dari HP jir
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      // 3. Tembak API buat Pairing / Klaim Alat
      // 🔥 Rutenya udah gua benerin sesuai main.go lu jir!
      final url = Uri.parse('https://livera.mataramteachingfactory.store/api/device/pair');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "serial_number": widget.sn,
          "pin": input, 
          "device_name": "LIVERA - ${widget.sn.substring(widget.sn.length - 3)}" // Kasih nama default otomatis
        }),
      );

      if (response.statusCode == 200 && mounted) {
        // --- KUNCI GACOR: UPDATE PROVIDER ---
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.updateSerialNumber(widget.sn);

        _showSuccess("Perangkat LIVERA Berhasil Diaktivasi!");

        // 4. Langsung banting ke Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(serialNumber: widget.sn),
          ),
          (route) => false,
        );
      } else {
        final data = jsonDecode(response.body);
        _showError(data['error'] ?? "Gagal aktivasi ke server!");
      }
    } catch (e) {
      _showError("Gagal nyambung ke server: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A4D41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A4D41).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFF0A4D41)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Otentikasi Perangkat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A4D41)),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  children: [
                    const TextSpan(text: 'Masukkan 6 Digit PIN untuk\n'),
                    TextSpan(
                      text: widget.sn,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // 🔥 TEXTFIELD UDAH JADI KHUSUS ANGKA JIR!
              TextField(
                controller: _passController,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number, // Munculin keyboard angka
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Tolak huruf kalau di-copas
                  LengthLimitingTextInputFormatter(6), // Mentokin 6 digit aja
                ],
                style: const TextStyle(letterSpacing: 8, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "••••••",
                  filled: true,
                  fillColor: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 2),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              const Text(
                'PIN ini tertera pada label fisik perangkat LIVERA Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A27),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'VERIFIKASI & AKTIVASI',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}