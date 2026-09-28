import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; 

class HumidityScreen extends StatefulWidget {
  const HumidityScreen({super.key});

  @override
  State<HumidityScreen> createState() => _HumidityScreenState();
}

class _HumidityScreenState extends State<HumidityScreen> {
  Timer? _timer;
  bool _isLoading = true;
  
  // Data dari Sensor & Database
  double _currentHumidity = 0.0;
  bool _isHumidifierOn = false;    // Status On/Off Humidifier (Manual)
  bool _isAutoMode = true;         // 🔥 Saklar Utama: TRUE = Otomatis, FALSE = Manual
  bool _isIotRealConnected = false; 

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // =================================================================
  // 📡 FUNGSI AMBIL DATA DARI BACKEND
  // =================================================================
  Future<void> _fetchData() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;

    if (sn.isEmpty || sn == "NONE") {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/sensor?sn=$sn'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentHumidity = (data['humidity'] ?? 0.0).toDouble();
            _isHumidifierOn = data['humidifier_status'] ?? false; 
            
            // Kolom penanda mode di database (pastikan backend mengirim ini ya bray)
            _isAutoMode = data['auto_mode_status'] ?? false; 
            _isIotRealConnected = data['is_iot_real'] ?? false;
            
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal fetch data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =================================================================
  // ⚙️ FUNGSI UBAH MODE (OTOMATIS VS MANUAL)
  // =================================================================
  Future<void> _toggleMode(bool useAuto) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;
    final token = userProvider.token;

    setState(() {
      _isAutoMode = useAuto;
    });

    try {
    await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/control/update'), // 🔥 Ubah jadi /update
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "serial_number": sn,
          "auto_mode": useAuto, 
        }),
      );
      print("🚀 Mode Berhasil Diubah ke: ${useAuto ? 'OTOMATIS' : 'MANUAL'}");
    } catch (e) {
      print("Gagal update mode: $e");
    }
  }

  // =================================================================
  // 🔌 FUNGSI KONTROL MANUAL ON/OFF
  // =================================================================
  Future<void> _toggleHumidifier(bool turnOn) async {
    // 🛑 VALIDASI KRITIKAL: Kalo mode otomatis, fungsi ini langsung diblokir bray!
    if (_isAutoMode) return; 

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;
    final token = userProvider.token;

    setState(() {
      _isHumidifierOn = turnOn; 
    });

    try {
      await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/control/update'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "serial_number": sn,
          "humidifier_status": turnOn, 
        }),
      );
    } catch (e) {
      print("Gagal manual control: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F1720) : const Color(0xFFFAFAFA);
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Dekorasi Lingkaran Atas & Bawah tetep aman bray
          Positioned(
            top: -100, right: -50,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE0F2FE).withOpacity(isDark ? 0.05 : 0.6))),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar Custom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Text("Humidity Control", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontFamily: 'Inter')),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            
                            // 1. MAIN STATUS CARD (Indikator Realtime)
                            _buildMainStatusCard(cardBg, isDark),
                            
                            const SizedBox(height: 24),
                            
                            // 2. SAKLAR UTAMA: SMART AUTO CONTROL MODE 
                            _buildSmartAutoCard(cardBg, isDark),
                            
                            const SizedBox(height: 32),
                            
                            // 3. SYSTEM PARAMETERS (MANUAL OVERRIDE SAKLAR)
                            Text(
                              "Manual Control Parameters",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: _isAutoMode 
                                    ? (isDark ? Colors.white24 : Colors.grey.shade400) // Burem kalo otomatis bray
                                    : (isDark ? Colors.white : Colors.black)
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Bungkus Toggle biar keliatan kekunci pas otomatis aktif
                            Opacity(
                              opacity: _isAutoMode ? 0.4 : 1.0, // Efek visual redup tanda ke-lock
                              child: _buildCustomToggleSwitch(cardBg, isDark),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Info Status Dinamis Deskriptif bawah tombol
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isAutoMode 
                                      ? "🔒 System is under Auto-Mode control. Manual switch disabled." 
                                      : "🔓 Manual Mode active. You can toggle the humidifier freely.",
                                    style: TextStyle(fontSize: 12, color: _isAutoMode ? const Color(0xFF0EA5E9) : Colors.grey.shade500, fontWeight: _isAutoMode ? FontWeight.w500 : FontWeight.normal),
                                  ),
                                ),
                              ],
                            ),
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

  // --- WIDGET PARAMETER INDIKATOR ---
  Widget _buildMainStatusCard(Color cardBg, bool isDark) {
    bool isCurrentlyMisting = (!_isAutoMode && _isHumidifierOn) || (_isAutoMode && _currentHumidity < 60.0 && _isIotRealConnected);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF0EA5E9), size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isCurrentlyMisting ? const Color(0xFFE0F2FE) : (isDark ? Colors.grey.shade800 : const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(20)),
                child: Text(isCurrentlyMisting ? "MISTING" : "IDLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCurrentlyMisting ? const Color(0xFF0EA5E9) : Colors.grey.shade500, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text("Current Humidity Level", style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_currentHumidity.toStringAsFixed(1), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, height: 1.0)),
              const SizedBox(width: 4),
              Text("%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  // --- SAKLAR OTOMATIS (YANG DI ATAS) ---
  Widget _buildSmartAutoCard(Color cardBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isAutoMode ? const Color(0xFF0EA5E9) : (isDark ? Colors.white10 : const Color(0xFFF3F4F6)), width: _isAutoMode ? 2 : 1),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Smart Auto Control", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 2),
              Text("Automate humidifier at 60%", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const Spacer(),
          // Switch Real Buat Nentuin Mode Otomatis/Manual bray
          Switch(
            value: _isAutoMode,
            activeColor: const Color(0xFF0EA5E9),
            onChanged: (value) {
              _toggleMode(value);
            },
          ),
        ],
      ),
    );
  }

  // --- SAKLAR MANUAL (YANG DI BAWAH / BISA KEKUNCI) ---
  Widget _buildCustomToggleSwitch(Color cardBg, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // MANUAL ON
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleHumidifier(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: (!_isAutoMode && _isHumidifierOn) ? const Color(0xFF10B981) : Colors.transparent, 
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text("MANUAL ON", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: (!_isAutoMode && _isHumidifierOn) ? Colors.white : Colors.grey.shade500)),
              ),
            ),
          ),
          
          // MANUAL OFF
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleHumidifier(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: (!_isAutoMode && !_isHumidifierOn) ? const Color(0xFFEF4444) : Colors.transparent, 
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text("MANUAL OFF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: (!_isAutoMode && !_isHumidifierOn) ? Colors.white : Colors.grey.shade500)),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 