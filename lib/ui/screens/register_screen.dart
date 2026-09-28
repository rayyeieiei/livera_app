import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livera_app/ui/screens/verify_otp_screen.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ==========================================
  // 🚀 LOGIC REGISTER KE BACKEND GO (GIN)
  // ==========================================
  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validasi Input
    if (email.isEmpty || password.isEmpty) {
      _showError("Email dan Password jangan dikosongin!");
      return;
    }
    if (password.length < 6) {
      _showError("Password minimal 6 karakter!");
      return;
    }
    if (password != confirmPassword) {
      _showError("Password-nya gak sama!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Tembak API Register Backend Lu
      final url = Uri.parse('https://livera.mataramteachingfactory.store/api/register');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "serial_number": "NONE", // Default awal sebelum tertaut alat
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (mounted) {
          _showSuccess("Akun berhasil dibuat! Silakan login.");
          // Pindah ke Login Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerifyOtpScreen(email: email)),
          );
        }
      } else {
        // Gagal dari server (misal email udah kedaftar)
        _showError(data['error'] ?? "Gagal daftar.");
      }
    } catch (e) {
      _showError("Gagal nyambung ke server: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.redAccent, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.green, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Join Livera", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0A4D41))),
              const SizedBox(height: 8),
              const Text("Buat akun dulu, konekin alatnya belakangan santai.", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),

              _buildLabel("Email Address"),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputStyle(Icons.email_outlined, "name@example.com"),
              ),
              const SizedBox(height: 24),

              _buildLabel("Password"),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputStyle(
                  Icons.lock_outline, 
                  "Min. 6 characters",
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel("Confirm Password"),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _inputStyle(
                  Icons.lock_reset, 
                  "Repeat password",
                  suffix: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A27),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "CREATE ACCOUNT", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    "Already have an account? Login", 
                    style: TextStyle(color: Color(0xFF0A4D41), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF072009), fontSize: 14)),
    );
  }

  InputDecoration _inputStyle(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF0A4D41), size: 22),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 1.5),
      ),
    );
  }
}