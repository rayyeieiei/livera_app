import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'manual_input_screen.dart';
import 'password_input_screen.dart';

class LoginQrScreen extends StatefulWidget {
  const LoginQrScreen({super.key});

  @override
  State<LoginQrScreen> createState() => _LoginQrScreenState();
}

// 🔥 FIX ANIMASI: Tambahin SingleTickerProviderStateMixin buat engine animasinya jir
class _LoginQrScreenState extends State<LoginQrScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    autoStart: false,
  );
  
  final ImagePicker _picker = ImagePicker();
  
  // Engine Animasi Scanner
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  
  bool _isFlashOn = false;
  bool _isNavigating = false;
  bool _isCameraRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Inisialisasi animasi radar naik turun
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startCameraSafely());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startCameraSafely();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopCameraSafely();
    }
  }

  Future<void> _startCameraSafely() async {
    if (_isNavigating || _isCameraRunning) return;
    try {
      await _cameraController.start();
      setState(() => _isCameraRunning = true);
    } catch (e) {
      debugPrint("Gagal nyalain kamera jir: $e");
    }
  }

  Future<void> _stopCameraSafely() async {
    if (!_isCameraRunning) return;
    try {
      await _cameraController.stop();
      setState(() {
        _isCameraRunning = false;
        _isFlashOn = false;
      });
    } catch (e) {
      debugPrint("Gagal matiin kamera jir: $e");
    }
  }

  Future<void> _handleDeviceVerification(String code) async {
    if (_isNavigating) return;
    
    await _stopCameraSafely();
    setState(() => _isNavigating = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menghubungkan ke server LIVERA...'), duration: Duration(milliseconds: 500)),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final url = Uri.parse('https://livera.mataramteachingfactory.store/api/verify-device');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", 
        },
        body: jsonEncode({"serial_number": code}),
      );

   // Di dalam fungsi _handleDeviceVerification setelah jsonDecode(response.body)
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        // 🔥 MODE BYPASS: Langsung lolos ke screen password tanpa ngecek is_paired lagi bray!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordInputScreen(
              sn: code, 
              correctPassword: data['password'] ?? "", 
            ),
          ),
        );
      } else {
        _showErrorSnackBar(data['error'] ?? 'Serial Number tidak terdaftar!');
        setState(() => _isNavigating = false);
        _startCameraSafely();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal nyambung ke server: $e');
      setState(() => _isNavigating = false);
      _startCameraSafely();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bool result = await _cameraController.analyzeImage(image.path);
      if (!result && mounted) {
        _showErrorSnackBar('Gak ada kode QR yang kedeteksi di gambar itu!');
      }
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isNavigating) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String rawCode = barcodes.first.rawValue!;
      
      // 🔥 LOGIKA BARU: Bongkar JSON QR Code biar gak bikin Golang 404 bray!
      String finalSerialNumber = rawCode;
      
      try {
        // Coba cek apakah isi QR nya itu data JSON
        if (rawCode.trim().startsWith('{') && rawCode.trim().endsWith('}')) {
          final Map<String, dynamic> parsedJson = jsonDecode(rawCode);
          if (parsedJson.containsKey('serial_number')) {
            finalSerialNumber = parsedJson['serial_number'].toString();
          }
        }
      } catch (e) {
        // Kalau error pas di-parse, berarti QR nya teks biasa/bukan JSON. Aman, pakai rawCode langsung.
        debugPrint("QR teks biasa kedeteksi, lanjut... $e");
      }

      // Kirim serial number yang udah bersih ke server
      _handleDeviceVerification(finalSerialNumber);
    }
  }

  // 🔥 Efek Transisi Layar yang lebih elegan jir
  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutQuart;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
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
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          'Tautkan LIVERA',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF0A4D41), fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Scan barcode di bawah perangkat Anda atau\npilih dari galeri untuk mulai bertani',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF4B5563), fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SCANNER AREA DENGAN ANIMASI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 280,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF0A4D41).withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                if (_isCameraRunning)
                                  MobileScanner(
                                    controller: _cameraController,
                                    onDetect: _onDetect,
                                  )
                                else
                                  const Center(
                                    child: Icon(Icons.videocam_off, color: Colors.white24, size: 40),
                                  ),
                                
                                // 🔥 UI KOTAK SCANNER & GARIS ANIMASI
                                Center(
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Container(
                                        width: 200, height: 200,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      if (_isCameraRunning)
                                        AnimatedBuilder(
                                          animation: _scanAnimation,
                                          builder: (context, child) {
                                            return Positioned(
                                              top: _scanAnimation.value * 196, // Bergerak dari 0 ke 196
                                              child: Container(
                                                width: 196,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2D5A27),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF62B660).withOpacity(0.8),
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                
                                Positioned(
                                  top: 16, right: 16,
                                  child: Column(
                                    children: [
                                      if (_isCameraRunning)
                                        GestureDetector(
                                          onTap: () {
                                            _cameraController.toggleTorch();
                                            setState(() => _isFlashOn = !_isFlashOn);
                                          },
                                          child: _buildIconButton(Icons.flash_on, _isFlashOn), 
                                        ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: _pickImageFromGallery,
                                        child: _buildIconButton(Icons.image_search_rounded, false), 
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isNavigating)
                                  Container(
                                    color: Colors.black54,
                                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                          ),
                          child: const Center(child: Icon(Icons.qr_code_2, size: 80, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // --- TOMBOL BAWAH DENGAN ANIMASI MUNCUL JIR ---
            Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 100, end: 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181818) : Colors.white,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -10))],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _stopCameraSafely();
                        if (!mounted) return;
                        
                        // 🔥 Pake animasi slide route pas dipencet
                        Navigator.push(
                          context,
                          _createSlideRoute(const ManualInputScreen()),
                        ).then((_) => _startCameraSafely());
                      },
                      icon: const Icon(Icons.keyboard_outlined, color: Color(0xFF0A4D41)),
                      label: const Text('Input Serial Number Manually', style: TextStyle(color: Color(0xFF0A4D41), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0A4D41), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF0A4D41)),
            SizedBox(width: 12),
            Expanded(child: Text('Barcode unik terdapat pada label di bagian bawah perangkat.', style: TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData iconData, bool isActive) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2D5A27) : Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: Colors.white, size: 22),
    );
  }
}