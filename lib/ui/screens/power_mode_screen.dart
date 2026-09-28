import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; 

class PowerModeScreen extends StatefulWidget {
  const PowerModeScreen({super.key});

  @override
  State<PowerModeScreen> createState() => _PowerModeScreenState();
}

class _PowerModeScreenState extends State<PowerModeScreen> {
  // --- STATE VARIABLES ---
  String _currentPowerMode = "monitor"; 
  bool _isLoading = true;
  Timer? _timer;
  bool _isCharging = false;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchPowerData();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) => _fetchPowerData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- API: AMBIL DATA POWER DARI GO (ANTI-LOADING ABADI) ---
  Future<void> _fetchPowerData() async {
    // 🔥 Kalau lagi ngirim settingan baru, STOP! Jangan ambil data lama!
    if (_isUpdating || !mounted) return; 

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;

    try {
      // 🔥 SINKRONISASI TOTAL: Hapus Header Token karena /api/control rute publik!
      // Kasih timeout 4 detik biar gak stuck nungguin server ngelamun
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/control?sn=$sn'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && mounted) {
        if (_isUpdating) return; 
        
        final data = jsonDecode(response.body);
        
        String fetchedMode = data['power_mode'] ?? "monitor";
        if (fetchedMode.isEmpty) fetchedMode = "monitor"; 

        setState(() {
          _currentPowerMode = fetchedMode;
          _isCharging = (_currentPowerMode == "monitor");
        });
      } else {
        print("❌ Server Balikin Eror di Power: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Gagal total sinkron data power: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePowerMode(String newMode) async {
    // Kalau user ngeklik mode yang emang udah aktif, cuekin aja
    if (_currentPowerMode == newMode) return; 

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    _isUpdating = true; 
    _timer?.cancel();

    // Ubah UI langsung jadi instan & responsif
    setState(() {
      _currentPowerMode = newMode;
      _isCharging = (newMode == "monitor");
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
          "power_mode": newMode, 
        }),
      );
    } catch (e) {
      debugPrint("Gagal update mode power ke cloud: $e");
    } 

    // 🔥 OBAT PENENANG: Tahan 3 detik ngasih waktu ke PostgreSQL buat nge-save, baru nyalain timer lagi!
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _isUpdating = false; // Buka gembok
        _fetchPowerData(); // Tarik data paling baru
        // Nyalain lagi polling otomatisnya
        _timer = Timer.periodic(const Duration(seconds: 4), (timer) => _fetchPowerData());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEmergencyMode = _currentPowerMode == "emergency";
    bool isPowerSaving = _currentPowerMode == "saving";
    bool isHealthMonitor = _currentPowerMode == "monitor";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A27)))
          : SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSystemPowerCard(),
                          const SizedBox(height: 32),
                          Text(
                            'pow_mgmt_header'.tr(),
                            style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingsList(isEmergencyMode, isPowerSaving, isHealthMonitor),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- KOMPONEN APPBAR ---
  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF111214), size: 22),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Text(
              'pow_title'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
            ),
          ),
          const SizedBox(width: 24), 
        ],
      ),
    );
  }

  // --- KOMPONEN 1: SYSTEM POWER STATUS CARD ---
  Widget _buildSystemPowerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 🔥 FIX LOGIC:
    // Persentase baterai kita bikin anteng/stabil, gak loncat-loncat aneh lagi.
    String batteryText = '87%'; 
    
    // YANG BERUBAH DRASTIS ITU CUMA SISA WAKTUNYA (RUNTIME)!
    String runtimeText = '3h 45m';
    
    if (_currentPowerMode == "saving") {
      // Mode hemat daya: Arus ditekan, umur alat jadi panjang!
      runtimeText = '6h 12m'; 
    } else if (_currentPowerMode == "emergency") {
      // Mode darurat: Mesin dipaksa kerja maksimal, baterai cepet abis!
      runtimeText = '1h 15m'; 
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x1AE2E8F0), blurRadius: 32, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'pow_status_header'.tr() , 
                        style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: 'Inter')
                      ),
                    ),
                    const SizedBox(width: 8), 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCharging ? const Color(0xFFE6FFEA) : Colors.amber.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6, 
                            decoration: BoxDecoration(
                              color: _isCharging ? const Color(0xFF34C759) : Colors.amber, 
                              shape: BoxShape.circle
                            )
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isCharging ? 'pow_status_active'.tr() : 'BATTERY MODE', 
                            style: TextStyle(
                              color: _isCharging ? const Color(0xFF34C759) : Colors.amber.shade800, 
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              fontFamily: 'Inter'
                            )
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isCharging ? Icons.bolt_rounded : Icons.battery_alert_rounded, 
                            size: 14, 
                            color: _isCharging ? const Color(0xFF34C759) : Colors.amber
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  batteryText, 
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 64, fontWeight: FontWeight.bold, height: 1, letterSpacing: -2, fontFamily: 'Inter')
                ),
                const SizedBox(height: 4),
                Text(
                  _isCharging ? '🔌 Charging...' : 'pow_battery_level'.tr(),
                  style: TextStyle(
                    color: _isCharging ? const Color(0xFF34C759) : const Color(0xFF9AA0A6), 
                    fontSize: 15, 
                    fontWeight: FontWeight.w500, 
                    fontFamily: 'Inter'
                  )
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), 
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.pinkAccent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'pow_runtime_label'.tr(), 
                              overflow: TextOverflow.ellipsis, 
                              maxLines: 1,
                              style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Inter')
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        runtimeText, // 👈 Yang berubah drastis cukup sisa waktunya doang
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10), 
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, size: 14, color: Colors.orangeAccent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'pow_health_label'.tr(), 
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Inter')
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'pow_health_val'.tr(args: ['11.8V']), 
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN 2: DAFTAR SETTINGS ---
  Widget _buildSettingsList(bool isEmergency, bool isSaving, bool isMonitor) {
    return Column(
      children: [
        _buildSettingTile(
          title: 'pow_emergency_title'.tr(),
          subtitle: 'pow_emergency_desc'.tr(),
          iconData: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFFF9F0A),
          value: isEmergency,
          onChanged: (val) {
            if (val) _updatePowerMode("emergency");
          },
        ),
        const SizedBox(height: 16),
        _buildSettingTile(
          title: 'pow_saving_title'.tr(),
          subtitle: 'pow_saving_desc'.tr(),
          iconData: Icons.eco_rounded, 
          iconColor: const Color(0xFF0A84FF),
          value: isSaving,
          onChanged: (val) {
            if (val) _updatePowerMode("saving");
          },
        ),
        const SizedBox(height: 16),
        _buildSettingTile(
          title: 'pow_monitor_title'.tr(),
          subtitle: 'pow_monitor_desc'.tr(),
          iconData: Icons.health_and_safety_rounded, 
          iconColor: const Color(0xFFFF9500),
          value: isMonitor,
          onChanged: (val) {
            if (val) _updatePowerMode("monitor");
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Icon(iconData, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, height: 1.4, fontFamily: 'Inter')),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          activeColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          activeTrackColor: const Color(0xFF2D5A27),
          inactiveThumbColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          inactiveTrackColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5EA),
          onChanged: onChanged,
        ),
      ],
    );
  }
}