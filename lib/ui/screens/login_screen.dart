import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart'; 

import '../../main.dart'; // Pastiin path UserProvider bener jir
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'login_qr_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false; // 🔥 State loading khusus Google
  bool _obscurePassword = true;

  // --- LOGIC LOGIN BIASA KE GIN BACKEND ---
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Email dan password jangan dikosongin!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://livera.mataramteachingfactory.store/api/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);

        String? snFromServer = data['user']['serial_number'];
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setToken(data['token']); 
        
        userProvider.setUserData(data['user']['name'] ?? "User Livera", email);

        if (snFromServer != null && snFromServer.isNotEmpty && snFromServer != "NONE") {
          userProvider.updateSerialNumber(snFromServer);
        } else {
          await prefs.remove('saved_serial');
        }

        if (mounted) {
          if (snFromServer != null && snFromServer.isNotEmpty && snFromServer != "NONE") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardScreen(serialNumber: userProvider.serialNumber)),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginQrScreen()),
              (route) => false,
            );
          }
        }
      } else {
        _showError(data['error'] ?? "Gagal login, cek lagi email/pass kamu!");
      }
    } catch (e) {
      _showError("Gagal nyambung ke server!: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
     await GoogleSignIn.instance.initialize(
        serverClientId: '52476403026-qftfnb9hjru6be8jf6c6fhgul559rbm8.apps.googleusercontent.com', 
      );
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return; 
      }

      final String email = googleUser.email;
      final String name = googleUser.displayName ?? "Pengguna Google";
      
      final url = Uri.parse('https://livera.mataramteachingfactory.store/api/google-login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "name": name,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        if (mounted) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setToken(token);
          userProvider.setUserData(name, email); 

          String? snFromServer = data['user']['serial_number'];
          
          if (snFromServer != null && snFromServer.isNotEmpty && snFromServer != "NONE") {
            userProvider.updateSerialNumber(snFromServer);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardScreen(serialNumber: snFromServer)),
              (route) => false,
            );
          } else {
            await prefs.remove('saved_serial');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginQrScreen()),
              (route) => false,
            );
          }
        }
      } else {
        _showError(data['error'] ?? 'Gagal login dari server backend');
      }
    } catch (e) {
      _showError('Gagal terkoneksi ke Google: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A27))) 
        : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0A4D41)),
              ),
              const SizedBox(height: 8),
              const Text("Masuk buat pantau alga kamu!", style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                  "Enter your password",
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading || _isGoogleLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A27),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Atau", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                ],
              ),
              
              const SizedBox(height: 24),

              // --- 🔥 TOMBOL GOOGLE LOGIN (PAKE ASET JIR!) ---
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: _isLoading || _isGoogleLoading ? null : _loginWithGoogle,
                  // 🔥 UPDATE BAGIAN IKON JIR!
                  icon: _isGoogleLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2D5A27)))
                      : Image.asset('assets/images/google_logo.webp', height: 24), // Fallback dihapus, langsung panggil webp jir!
                  label: const Text(
                    "Login dengan Google", 
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun? "),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text("Daftar Sekarang", style: TextStyle(color: Color(0xFF0A4D41), fontWeight: FontWeight.bold)),
                    ),
                  ],
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