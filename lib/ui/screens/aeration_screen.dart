import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; 
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';  

class AerationScreen extends StatefulWidget {
  const AerationScreen({super.key});

  @override
  State<AerationScreen> createState() => _AerationScreenState();
}

class _AerationScreenState extends State<AerationScreen> {
  // --- STATE VARIABLES ---
  double _flowRate = 0; 
  String airFlowDisplay = '0'; 
  Timer? _fetchTimer;
  Timer? _rampTimer; 
  bool _isLoading = true;
  
  // 🔥 FIX MUTLAK: Pemisah status tombol fisik dengan target hitung animasi!
  bool _isSystemOn = false; 
  double _targetFlowRate = 0.0; 

  // --- API LOGIC: FETCH DATA DARI GO BACKEND ---
  Future<void> _fetchAerationData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;

    try {
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/control?sn=$sn'),
        headers: {"Authorization": "Bearer ${userProvider.token}"},
      ).timeout(const Duration(seconds: 2)); // Batasi nunggu 2 detik aja bray biar gak lola

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          var rawStatus = data['air_status'];
          bool fetchedStatus = false;
          if (rawStatus is bool) {
            fetchedStatus = rawStatus;
          } else if (rawStatus is int) {
            fetchedStatus = (rawStatus == 1);
          } else if (rawStatus is String) {
            fetchedStatus = (rawStatus == "true" || rawStatus == "1");
          }

          _isSystemOn = fetchedStatus;
          
          if (_isSystemOn) {
            var rawFlow = data['airflow'];
            double parsedFlow = (rawFlow != null) ? double.tryParse(rawFlow.toString()) ?? 0.0 : 0.0;
            _targetFlowRate = (parsedFlow > 0) ? parsedFlow : 85.0; 
          } else {
            _targetFlowRate = 0.0;
          }
          
          _startFanRampEngine();
          _isLoading = false; // Berhenti loading bray bray
        });
      }
    } catch (e) {
      debugPrint("🚨 Internet RTO/Putus bray, Trigger Mock Data Lokal Aktif: $e");
      
      // 🔥 FIX LOADING ABADI: Kalo internet putus, paksa matikan loading biar layarnya kebuka!
      if (mounted) {
        setState(() {
          if (_isSystemOn) {
            _targetFlowRate = 85.0; 
          } else {
            _targetFlowRate = 0.0;
          }
          _startFanRampEngine();
          _isLoading = false; // 🛡️ SUNTIKAN SUCI: Hancurkan loading abadi detik ini juga bray!
        });
      }
    } finally {
      // Pastikan loader mati dalam kondisi apapun
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 🔥 LOGIC ANIMASI: MENGHITUNG HALUS DARI 0 MENUJU ANGKA BACKEND ---
  void _startFanRampEngine() {
    if (_flowRate == _targetFlowRate) return;
    _rampTimer?.cancel(); 
    
    _rampTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_flowRate < _targetFlowRate) {
          _flowRate += 2.0; // Naik perlahan biar motor kipas gak kaget cok
          if (_flowRate >= _targetFlowRate) {
            _flowRate = _targetFlowRate;
            timer.cancel();
          }
        } else if (_flowRate > _targetFlowRate) {
          _flowRate -= 3.0; // Deselerasi ngerem halus pas dimatiin
          if (_flowRate <= _targetFlowRate) {
            _flowRate = _targetFlowRate;
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
        airFlowDisplay = _flowRate.toStringAsFixed(0);
      });
    });
  }

  // --- API LOGIC: UPDATE STATUS TOMBOL (ON/OFF) KE SERVER ---
  Future<void> _updateAerationStatus(bool statusTarget) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // 🔥 OPTIMISTIC UI KELAS DEWA: Layar langsung joget lari duluan tanpa nunggu server loading!
    setState(() {
      _isSystemOn = statusTarget;
      if (statusTarget) {
        _targetFlowRate = 85.0; // Langsung picu target 85 bray
        _startFanRampEngine();
      } else {
        _targetFlowRate = 0.0; // Langsung ngerem total
        _startFanRampEngine();
      }
    });

    try {
      await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/control/update'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${userProvider.token}"
        },
        body: jsonEncode({
          "serial_number": userProvider.serialNumber,
          "air_status": statusTarget,
          // 🔥 BACKEND SYNC: Suntik angkanya langsung ke payload biar DB lu gak kosongan/0!
          "airflow": statusTarget ? 85 : 0, 
        }),
      );
    } catch (e) {
      debugPrint("Gagal update status aerasi ke server Go: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAerationData();
    // Re-fetch data tiap 3 detik biar sinkronisasi latar belakang berjalan indah
    _fetchTimer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchAerationData());
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    _rampTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : const Color(0xFF111318);
    final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF95A1AD);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFFF)))
        : Stack(
            children: [
              Positioned(
                left: 165, top: 60,
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFFF).withOpacity(isDark ? 0.05 : 0.08), 
                    shape: BoxShape.circle
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: SizedBox(
                  height: 220,
                  child: CustomPaint(painter: AerationWavePainter(isDark: isDark)),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(mainTextColor),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          children: [
                            _buildOxygenLevelCard(cardColor, mainTextColor, secondaryTextColor, isDark),
                            const SizedBox(height: 24),
                            _buildSmartAerationComingSoon(cardColor, mainTextColor, secondaryTextColor, isDark),
                            const SizedBox(height: 32),
                            _buildManualControlSection(mainTextColor, isDark),
                            const SizedBox(height: 180),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildAppBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text('aero_title'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOxygenLevelCard(Color bg, Color titleColor, Color subColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFF00BFFF).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.air_rounded, color: Color(0xFF00BFFF)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: (_isSystemOn ? const Color(0xFF1EC070) : Colors.grey).withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(_isSystemOn ? 'ACTIVE' : 'INACTIVE', style: TextStyle(color: _isSystemOn ? const Color(0xFF1EC070) : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('aero_current_label'.tr(), style: TextStyle(color: subColor, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(airFlowDisplay, style: TextStyle(color: titleColor, fontSize: 56, fontWeight: FontWeight.bold, letterSpacing: -2)),
              const SizedBox(width: 4),
              Text('%', style: TextStyle(color: subColor, fontSize: 24)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAerationComingSoon(Color bg, Color titleColor, Color subColor, bool isDark) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('aero_smart_title'.tr(), style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w600))),
                const Switch(value: false, onChanged: null),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF00BFFF), borderRadius: BorderRadius.circular(20)),
              child: const Text("🚀COMING SOON IN LIVERA 2.0", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildManualControlSection(Color titleColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('aero_params_title'.tr(), style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161616) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
          ),
          child: Row(
            children: [
              // --- TOMBOL ON (DIJAMIN SOLID & BISA DIPENCET KAPANPUN) ---
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_isSystemOn) {
                      _updateAerationStatus(true);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isSystemOn ? const Color(0xFF1EC070) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isSystemOn 
                          ? [BoxShadow(color: const Color(0xFF1EC070).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] 
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        "ON",
                        style: TextStyle(
                          color: _isSystemOn ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // --- TOMBOL OFF ---
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isSystemOn) {
                      _updateAerationStatus(false);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: !_isSystemOn ? const Color(0xFFEF4444) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: !_isSystemOn 
                          ? [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] 
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        "OFF",
                        style: TextStyle(
                          color: !_isSystemOn ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Icon(
              _isSystemOn ? Icons.check_circle_rounded : Icons.info_outline_rounded, 
              color: _isSystemOn ? const Color(0xFF1EC070) : Colors.grey, 
              size: 16
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _flowRate == _targetFlowRate
                    ? (_isSystemOn ? "Aeration pump is running at synchronized speed." : "Aeration pump is completely stopped.")
                    : (_isSystemOn ? "Synchronizing... Incrementing up to ${_targetFlowRate.toStringAsFixed(0)}%." : "Stopping safely... Slowing down to 0%."),
                style: TextStyle(color: _isSystemOn ? const Color(0xFF1EC070) : Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AerationWavePainter extends CustomPainter {
  final bool isDark;
  AerationWavePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final Color waveBaseColor = const Color(0xFF00BFFF);
    final Paint paint = Paint()..style = PaintingStyle.fill;
    paint.color = waveBaseColor.withOpacity(isDark ? 0.1 : 0.15);
    final Path backWave = Path();
    backWave.moveTo(0, size.height * 0.6);
    backWave.quadraticBezierTo(size.width * 0.25, size.height * 0.4, size.width * 0.5, size.height * 0.6);
    backWave.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.5);
    backWave.lineTo(size.width, size.height);
    backWave.lineTo(0, size.height);
    canvas.drawPath(backWave, paint);
    paint.color = waveBaseColor.withOpacity(isDark ? 0.2 : 0.25);
    final Path frontWave = Path();
    frontWave.moveTo(0, size.height * 0.8);
    frontWave.quadraticBezierTo(size.width * 0.25, size.height * 0.95, size.width * 0.5, size.height * 0.7);
    frontWave.quadraticBezierTo(size.width * 0.75, size.height * 0.45, size.width, size.height * 0.65);
    frontWave.lineTo(size.width, size.height);
    frontWave.lineTo(0, size.height);
    canvas.drawPath(frontWave, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}