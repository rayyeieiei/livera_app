import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; // Ambil UserProvider lu jir
import 'package:easy_localization/easy_localization.dart';

class LightingManagementScreen extends StatefulWidget {
  const LightingManagementScreen({super.key});

  @override
  State<LightingManagementScreen> createState() => _LightingManagementScreenState();
}

class _LightingManagementScreenState extends State<LightingManagementScreen> {
  // --- STATE VARIABLES ---
  double _lightIntensity = 0.0;
  bool _isLightOn = false;
  bool _isAutoMode = true;
  Timer? _timer;
  bool _isInitialLoading = true;

 // --- SINKRONISASI JALUR DUMMY TERPUSAT KE ROUTE API SENSOR JIR ---
  Future<void> _fetchControlData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;

    try {
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/sensor?sn=$sn'),
      );

      if (response.statusCode == 200 && mounted) {
        print("📡 LIGHTING SYNC DATA JIR: ${response.body}");
        final data = jsonDecode(response.body);
        
        setState(() {
          _lightIntensity = (data['light'] ?? 0).toDouble();
          
          _isLightOn = _lightIntensity > 0;
          
          _isAutoMode = true; 
        });
      } else {
        print("❌ LIGHTING SYNC ERROR: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Gagal sinkronisasi data Lighting ke Dashboard: $e");
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchControlData();
    // Update tiap 3 detik biar angkanya "Live" dari server
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) _fetchControlData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = const Color(0xFFFF69B4); 

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('light_title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isInitialLoading 
        ? Center(child: CircularProgressIndicator(color: mainColor))
        : SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainValueCard(isDark, mainColor),
                        const SizedBox(height: 32),
                        _buildManualControlSection(isDark, mainColor), // Slider mati di sini jir
                        const SizedBox(height: 32),
                        _buildAiInsightCard(isDark, mainColor),
                      ],
                    ),
                  ),
                ),
                _buildAutoModeCard(isDark, mainColor),
              ],
            ),
          ),
    );
  }

  // --- KOTAK MONITORING UTAMA ---
  Widget _buildMainValueCard(bool isDark, Color mainColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: mainColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.wb_sunny_rounded, color: mainColor, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isLightOn ? const Color(0xFFE8F7FF) : Colors.grey.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Text(
                  _isLightOn ? 'LIGHT ON' : 'LIGHT OFF', 
                  style: TextStyle(color: _isLightOn ? const Color(0xFF1EC070) : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${_lightIntensity.toInt()} µmol', 
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)
          ),
          const Text('Current PAR Intensity', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  // --- MANUAL OVERRIDE (MATI/READ-ONLY) ---
  Widget _buildManualControlSection(bool isDark, Color mainColor) {
    return Opacity(
      opacity: 0.4, // Kita buat redup biar ketauan gak bisa dipake jir
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manual Override', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: mainColor,
              inactiveTrackColor: Colors.grey.withOpacity(0.2),
              thumbColor: mainColor,
              trackHeight: 8,
              // Buat thumb-nya transparan biar makin tegas kalau gak bisa digeser
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0), 
            ),
            child: Slider(
              value: _lightIntensity.clamp(0, 1000),
              min: 0, max: 1000,
              onChanged: null, // MATIIN JIR! (Set null biar gak bisa digeser)
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 µmol', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('1000 µmol', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(bool isDark, Color mainColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: mainColor, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Light levels are managed by LIVERA system. Manual control is restricted in current version.",
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoModeCard(bool isDark, Color mainColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF161616) : Colors.white),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Auto Lighting Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch.adaptive(value: true, onChanged: null),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: mainColor, borderRadius: BorderRadius.circular(20)),
            child: const Text("🚀 COMING SOON IN 2.0", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}