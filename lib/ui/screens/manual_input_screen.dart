import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'password_input_screen.dart';
import 'serial_formater_screen.dart'; 

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final TextEditingController _serialController = TextEditingController(text: "LVRA-");
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serialController.selection = TextSelection.fromPosition(
      TextPosition(offset: _serialController.text.length),
    );
  }

  // --- 🚀 LOGIC VERIFIKASI KE BACKEND GO (GIN) ---
  Future<void> _processDeviceVerification(String sn) async {
    final cleanSN = sn.trim().toUpperCase();

    if (cleanSN.length < 11) {
      _showSnackBar('Serial Number kurang lengkap! (Contoh: LVRA-X1-001)', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final url = Uri.parse('https://livera.mataramteachingfactory.store/api/verify-device');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          // 🔥 HAPUS ATAU KOMEN BARIS AUTHORIZATION DI BAWAH INI
          // "Authorization": "Bearer $token", 
        },
        body: jsonEncode({"serial_number": cleanSN}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        // SUKSES: Device ketemu di Database Server
        if (data['is_paired'] == true) {
          _showSnackBar('Perangkat sudah aktif. Masukkan password fisik.', Colors.blueGrey);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordInputScreen(
              sn: cleanSN,
              correctPassword: data['password'] ?? "",
            ),
          ),
        );
      } else {
        // GAGAL: SN gak ada atau error server
        _showError(data['error'] ?? "Serial Number tidak terdaftar di sistem!");
      }
    } catch (e) {
      _showError("Duh, gagal konek ke server: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    _showSnackBar(message, Colors.redAccent);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }

  @override
  void dispose() {
    _serialController.dispose();
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
      title: const Text('Connect Device', 
        style: TextStyle(color: Color(0xFF0A4D41), fontWeight: FontWeight.bold)),
      centerTitle: true,
    ),
    // 🔥 SUNTIKAN PENYELAMAT DI SINI JIR
    body: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight, // Maksa tinggi minimal sepanjang layar
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manual Input', 
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0A4D41))),
                    const SizedBox(height: 8),
                    const Text('Masukkan Serial Number yang tertera pada label perangkat.', 
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(height: 40),
                    
                    TextField(
                      controller: _serialController,
                      autofocus: true,
                      inputFormatters: [LiveraSerialFormatter()],
                      decoration: InputDecoration(
                        labelText: "Serial Number",
                        labelStyle: const TextStyle(color: Color(0xFF0A4D41)),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(22),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 20),
                          onPressed: () {
                            _serialController.text = "LVRA-";
                            _serialController.selection = const TextSelection.collapsed(offset: 5);
                          },
                        ),
                      ),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, fontFamily: 'Monospace'),
                    ),
                    
                    const Spacer(), // Sekarang aman dipake di sini jir!
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _processDeviceVerification(_serialController.text), 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5A27),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('VERIFY & CONTINUE', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
}