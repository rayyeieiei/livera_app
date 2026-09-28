import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'lighting_management_screen.dart';
import 'aeration_screen.dart'; 
import 'nutrient_screen.dart';
import 'power_mode_screen.dart';
import 'analytics_screen.dart'; 
import 'harvesting_screen.dart'; 
import 'history_utama.dart';
import 'settings_screen.dart';
import 'manual_input_screen.dart'; 
import 'profile_screen.dart';
import 'login_qr_screen.dart'; // 🔥 IMPORT BARU: Biar bisa pindah ke layar Scanner
import '../../models/sensor_models.dart'; 
import '../../models/device_models.dart';
import 'package:livera_app/main.dart'; 
import '../../services/notification_service.dart'; 
import 'advanced_data_sheet.dart';
import 'humidity_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String serialNumber;
  const DashboardScreen({super.key, required this.serialNumber});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

  void _showGasDetailsSheet(BuildContext context, String currentCo2Str) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double co2 = double.tryParse(currentCo2Str) ?? 450.0;
    
    // Simulasi rasio gas dari MQ135 berdasarkan nilai CO2 (Buat keperluan UI prototipe)
    double nh3 = co2 * 0.00015;  // Amonia
    double voc = co2 * 0.00025;  // VOC (Alkohol/Etanol)
    double nox = co2 * 0.00010;  // Nitrogen Oksida
    double smoke = co2 * 0.00005;// Asap & Sulfida

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Rincian Kualitas Udara (MQ-135)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Spektrum gas yang dideteksi oleh sensor di sekitar bioreaktor alga.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildGasDetailItem("Karbon Dioksida (CO₂)", "${co2.toStringAsFixed(0)} ppm", "Indikator sirkulasi udara utama", Colors.green, isDark),
                  _buildGasDetailItem("Senyawa VOC", "${voc.toStringAsFixed(3)} ppm", "Benzena, Alkohol, Toluena", Colors.orange, isDark),
                  _buildGasDetailItem("Amonia (NH₃)", "${nh3.toStringAsFixed(3)} ppm", "Deteksi bau/limbah organik", Colors.blue, isDark),
                  _buildGasDetailItem("Nitrogen Oksida (NOx)", "${nox.toStringAsFixed(3)} ppm", "Asap pembakaran kendaraan", Colors.redAccent, isDark),
                  _buildGasDetailItem("Asap & Sulfida", "${smoke.toStringAsFixed(3)} ppm", "Deteksi asap pekat/belerang", Colors.grey, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasDetailItem(String name, String value, String desc, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.air, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE VARIABLES ---
  String co2Level = '--'; 
  String tempLevel = '--';
  String airFlow = '--';   
  String lightIntensity = '--'; 
  String phLevel = '--';
  String o2Level = '--';   
  String _activeMode = 'Auto'; 
  
  double _phValue = 0.0;
  double _tempValue = 0.0;
  double _airflowValue = 0.0;
  double _lightValue = 0.0;
  int _nutriN = 0;
  int _nutriP = 0;
  int _nutriK = 0;
  
  bool isServerOnline = false; 
  int _selectedIndex = 0;
  bool _isLoadingContent = true;
  Timer? _timer;
  double efficiency = 0.0;
  bool _hasNotifiedCo2 = false;
  bool _hasNotifiedPhLow = false;
  bool _hasNotifiedPhHigh = false;
  bool _hasNotifiedLight = false;

  void checkDeviceCondition(double co2Val, double phVal, double lightVal) {
    // 1. Cek kadar gas CO2 berlebih
    if (co2Val > 1500) {
      if (!_hasNotifiedCo2) { 
        NotificationService.showEmergencyNotification(
          id: 1,
          title: '🚨 KONDISI DARURAT: CO2 Overload!',
          body: 'Kadar CO2 mencapai ${co2Val.toStringAsFixed(0)} ppm! Kinerja alga LIVERA dipaksa maksimal!',
        );
        _hasNotifiedCo2 = true; 
      }
    } else {
      _hasNotifiedCo2 = false; 
    }

    // 2. Cek keasaman air reaktor alga (pH)
    if (phVal < 6.0 && phVal > 0) { 
      if (!_hasNotifiedPhLow) {
        NotificationService.showEmergencyNotification(
          id: 2,
          title: '🚨 AIR REAKTOR ASAM: pH Drop!',
          body: 'Tingkat keasaman kritis di angka ${phVal.toStringAsFixed(1)}! Segera lakukan netralisasi air!',
        );
        _hasNotifiedPhLow = true;
      }
    } else if (phVal > 8.5) {
      if (!_hasNotifiedPhHigh) {
        NotificationService.showEmergencyNotification(
          id: 4,
          title: '🚨 AIR REAKTOR BASA: pH Tinggi!',
          body: 'Tingkat pH melonjak ke angka ${phVal.toStringAsFixed(1)}! Berbahaya bagi ekosistem Chlorella!',
        );
        _hasNotifiedPhHigh = true;
      }
    } else {
      _hasNotifiedPhLow = false;
      _hasNotifiedPhHigh = false;
    }

    // 3. Cek kegagalan sistem cahaya fotosintesis (Lampu Anomali)
    if (lightVal < 100 && isServerOnline) {
      if (!_hasNotifiedLight) { 
        NotificationService.showEmergencyNotification(
          id: 3,
          title: '💡 PERINGATAN: Fotosintesis Terganggu!',
          body: 'Intensitas cahaya drop hingga ${lightVal.toStringAsFixed(0)} μmol. Periksa lampu LED reaktor LIVERA Anda!',
        );
        _hasNotifiedLight = true; 
      }
    } else {
      _hasNotifiedLight = false; 
    }
  }

  // --- LOGIKA FETCH DATA ---
  Future<SensorData> fetchSensorData(String sn) async {
    final url = Uri.parse('https://livera.mataramteachingfactory.store/api/sensor?sn=$sn');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return SensorData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception();
      }
    } catch (e) {
      debugPrint("Gagal narik data sensor: $e");
      return SensorData(ph: 0, temperature: 0, co2: 0, airflow: 0, biomass: 0, light: 0, isOnline: false);
    }
  }

  void _updateSensorData() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String sn = userProvider.serialNumber;
    bool isUnregistered = sn.isEmpty || sn == "NONE";

    if (isUnregistered) {
      setState(() {
        isServerOnline = false;
        _resetData();
      });
      return;
    }

    final data = await fetchSensorData(sn);
    if (mounted) {
      setState(() {
        isServerOnline = data.isOnline;
        if (isServerOnline) {
          phLevel = data.ph.toStringAsFixed(1);
          tempLevel = data.temperature.toStringAsFixed(1);
          co2Level = data.co2.toStringAsFixed(0);      
          airFlow = data.airflow.toStringAsFixed(0);    
          lightIntensity = data.light.toStringAsFixed(0); 
          o2Level = "21"; 
          
          double tempScore = (data.temperature / 40.0) * 100; 
          double phScore = (data.ph / 14.0) * 100;            
          double co2Score = (data.co2 / 1000.0) * 100;        
          double lightScore = (data.light / 1000.0) * 100;    
          
          efficiency = (tempScore + phScore + co2Score + lightScore) / 4.0;
          
          if (efficiency > 100) efficiency = 100;
          
          checkDeviceCondition(data.co2, data.ph, data.light); 
          
        } else {
          _resetData();
        }
      });
    }
  }

  void _resetData() {
    phLevel = '--'; tempLevel = '--'; co2Level = '--';
    airFlow = '--'; lightIntensity = '--'; efficiency = 0.0;
  }

  @override
  void initState() {
    super.initState();
    _updateSensorData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _updateSensorData());
    Future.delayed(const Duration(milliseconds: 800), () { 
      if (mounted) setState(() => _isLoadingContent = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

// --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    final userProvider = userProviderWatch(context);
    bool isUnregistered = userProvider.serialNumber.isEmpty || userProvider.serialNumber == "NONE";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: isUnregistered 
        ? FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManualInputScreen())),
            backgroundColor: const Color(0xFF22C55E),
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null,
      floatingActionButtonLocation: CustomFloatingLocation(),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 80, 
            child: _isLoadingContent 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A27)))
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350), 
                  switchInCurve: Curves.easeOutCubic, 
                  switchOutCurve: Curves.easeInCubic, 
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.04), 
                          end: Offset.zero, 
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    key: ValueKey<int>(_selectedIndex),
                    height: double.infinity,
                    width: double.infinity,
                    child: _getSelectedFrame(isUnregistered),
                  ),
                ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNavigationBar()),
        ],
      ),
    );
  }

  UserProvider userProviderWatch(BuildContext context) => context.watch<UserProvider>();

  Widget _getSelectedFrame(bool isUnregistered) {
    switch (_selectedIndex) {
      case 0: return _buildFrameHome(isUnregistered);
      case 1: return const AnalyticsScreen();
      case 2: return const HarvestingScreen(); 
      case 3: return const HistoryUtama();
      case 4: return const SettingsScreen();
      default: return _buildFrameHome(isUnregistered);
    }
  }

  Widget _buildFrameHome(bool isUnregistered) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10), 
          _buildTopBar(), 
          if (isUnregistered) _buildRegisterWarning(),
          const SizedBox(height: 10), 
          _buildMainStatusCard(isUnregistered),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'dash_ecosystem'.tr()),
          const SizedBox(height: 16),
          _buildEcosystemGrid(),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'dash_env_params'.tr(), actionText: 'View All'),
          const SizedBox(height: 16),
          _buildEnvironmentalList(isUnregistered),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'dash_system_modes'.tr()),
          const SizedBox(height: 16),
          _buildSystemModes(),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Recent Activity'),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();
    return Container(
      height: 80, 
      alignment: Alignment.center, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: userProvider.imagePath != null ? FileImage(File(userProvider.imagePath!)) : null,
              child: userProvider.imagePath == null ? const Icon(Icons.person) : null,
            ),
          ),
          Row(
            children: [
              Image.asset('assets/images/logo_livera_full.webp', height: 80, fit: BoxFit.contain),
              const SizedBox(width: 8),
              const Text("V2.0", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _showNotificationSheet(context);
            },
            child: Stack(
              children: [
                Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : const Color(0xFF0F1720), size: 30),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6, 
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Alerts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Mark all read", style: TextStyle(color: Color(0xFF2D5A27))),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildNotificationItem("🚨 CO2 Overload Prevented", "Algae reactor automatically optimized airflow to absorb excess CO2.", "10 mins ago", isDark, true),
                  const Divider(height: 24),
                  _buildNotificationItem("💡 Light Intensity Adjusted", "Photosynthesis LED matrix is now running at optimal 85%.", "2 hours ago", isDark, false),
                  const Divider(height: 24),
                  _buildNotificationItem("💧 pH Level Normalized", "Water acidity returned to safe range (7.2) for Chlorella growth.", "Yesterday", isDark, false),
                  const Divider(height: 24),
                  _buildNotificationItem("✅ System Online", "LIVERA Purifier has successfully connected to the cloud server.", "Yesterday", isDark, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String desc, String time, bool isDark, bool isUnread) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFF2D5A27).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUnread ? Icons.warning_amber_rounded : Icons.notifications_active_rounded, 
            color: isUnread ? const Color(0xFFEF4444) : const Color(0xFF2D5A27), 
            size: 20
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.4)),
              const SizedBox(height: 6),
              Text(time, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatusCard(bool isUnregistered) {
    bool showData = !isUnregistered && isServerOnline;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D5A27), 
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('dash_photobioreactor'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              _buildActiveBadge(isUnregistered),
            ],
          ),
          const SizedBox(height: 32),
          Text(showData ? '${efficiency.toStringAsFixed(1)}%' : '-', style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold, height: 1.0)),
          const SizedBox(height: 8),
          Text('dash_growth_efficiency'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildMiniStatBox(icon: Icons.eco, iconColor: Colors.pink, title: 'dash_biomass'.tr(), value: showData ? '2.4 g/L' : '-'),
              const SizedBox(width: 12),
              _buildMiniStatBox(icon: Icons.water_drop, iconColor: Colors.tealAccent[400]!, title: 'O₂ Level', value: showData ? '21%' : '-'),
              const SizedBox(width: 12),
              _buildMiniStatBox(icon: Icons.thermostat, iconColor: Colors.orange, title: 'Temp', value: showData ? '$tempLevel°C' : '-'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniStatBox({required IconData icon, required Color iconColor, required String title, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }


  Widget _buildEcosystemGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // 🔥 Rahasianya di sini, bisa digeser ke samping!
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildEcoCard('dash_lighting'.tr(), Icons.lightbulb_outline, [const Color(0xFFE91E63), const Color(0xFFF472B6)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LightingManagementScreen()))),
          const SizedBox(width: 10),
          _buildEcoCard('Air', Icons.air, [const Color(0xFF00BCD4), const Color(0xFF60A5FA)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AerationScreen()))),
          const SizedBox(width: 10),
          _buildEcoCard('Nutri', Icons.science_outlined, [const Color(0xFF2D5A27), const Color(0xFF16A34A)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutrientScreen()))),
          const SizedBox(width: 10),
          _buildEcoCard('Power', Icons.bolt, [const Color(0xFFFFCA28), const Color(0xFFF57F17)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PowerModeScreen()))),
          const SizedBox(width: 10),
          
          // 🔥 KARTU HUMIDITY BARU (Warna Ungu biar beda dari yang lain)
          _buildEcoCard('Humid', Icons.waves_rounded, [const Color(0xFF8B5CF6), const Color(0xFFC084FC)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HumidityScreen()))), 
        ], 
      ),
    );   
  }

  Widget _buildEcoCard(String title, IconData icon, List<Color> colors, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Hapus widget "Expanded" karena di dalam Horizontal Scroll gak boleh pake Expanded
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, // 🔥 Kasih lebar fix 80 pixel biar semua kartu ukurannya seragam
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
          borderRadius: BorderRadius.circular(20)
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(gradient: LinearGradient(colors: colors), shape: BoxShape.circle), 
              child: Icon(icon, color: Colors.white, size: 20)
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalList(bool isUnregistered) {
    bool showData = !isUnregistered && isServerOnline;
    return Column(
      children: [
        _buildEnvParamCard('dash_light'.tr(), showData ? '$lightIntensity μmol' : '-', Icons.wb_sunny, [const Color(0xFFE91E63), const Color(0xFFF472B6)]),
        const SizedBox(height: 12),
        _buildEnvParamCard('dash_ph'.tr(), showData ? phLevel : '-', Icons.water_drop, [const Color(0xFF00BCD4), const Color(0xFF60A5FA)]),
        const SizedBox(height: 12),
        
        // 🔥 TAMBAHAN: Kartu CO2 sekarang ada onTap-nya
        _buildEnvParamCard(
          'dash_co2'.tr(), 
          showData ? '$co2Level ppm' : '-', 
          Icons.cloud, 
          [const Color(0xFF2D5A27), const Color(0xFF16A34A)],
          onTap: showData ? () => _showGasDetailsSheet(context, co2Level) : null,
        ),
        
        const SizedBox(height: 12),
        _buildEnvParamCard('dash_airflow'.tr(), showData ? '$airFlow%' : '-', Icons.air, [const Color(0xFF00BCD4), const Color(0xFF60A5FA)]),
      ],
    );
  }

Widget _buildEnvParamCard(String title, String val, IconData icon, List<Color> colors, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap, // 🔥 Tambahan biar kartu bisa diklik
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSystemModes() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> modes = ['Auto', 'Manual', 'Research'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double totalWidth = constraints.maxWidth;
          double tabWidth = totalWidth / modes.length;

          int activeIndex = modes.indexOf(_activeMode);
          if (activeIndex == -1) activeIndex = 0;

          return SizedBox(
            height: 52,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  left: activeIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5A27),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D5A27).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                  ),
                ),
                Row(
                  children: modes.map((m) { 
                    bool isSelected = _activeMode == m;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_activeMode == m) return;
                          
                          setState(() {
                            _activeMode = m;
                          });

                          bool isManaged = (m == 'Auto' || m == 'Research');
                          _updateGlobalSystemMode(isManaged, m.toLowerCase());
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                            child: Text(m),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  OverlayEntry? _currentOverlay;

  Future<void> _updateGlobalSystemMode(bool isManaged, String powerModeString) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;
    final token = userProvider.token;

    if (sn.isEmpty || sn == "NONE") return;

    try {
      final response = await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/control/update'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "serial_number": sn,
          "managed_mode": isManaged,
          "power_mode": powerModeString,
        }),
      );

      if (response.statusCode == 200) {
        print("🚀 BACKEND SYNCED: Mode Global Berubah -> $powerModeString");
        
        if (mounted) {
          _currentOverlay?.remove();
          _currentOverlay = null;

          _currentOverlay = OverlayEntry(
            builder: (context) => Positioned(
              top: MediaQuery.of(context).padding.top + 12, 
              left: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5A27), 
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '⚡ System switched to ${powerModeString.toUpperCase()} Mode!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          Overlay.of(context).insert(_currentOverlay!);

          final localOverlay = _currentOverlay; 
          Future.delayed(const Duration(milliseconds: 800), () {
            if (localOverlay != null && localOverlay.mounted) {
              localOverlay.remove();
              if (_currentOverlay == localOverlay) {
                _currentOverlay = null;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Gagal nembak update mode global ke cloud Go: $e");
    }
  }
  
  Widget _buildRecentActivityCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _buildActivityItem(
            "Nutrient injection completed",
            "2 minutes ago",
            Icons.check_rounded,
            const Color(0xFF22C55E),
            const Color(0xFF22C55E).withOpacity(0.1),
          ),
          const Divider(height: 30, thickness: 1, color: Colors.black12),
          _buildActivityItem(
            "pH adjusted to optimal level",
            "15 minutes ago",
            Icons.water_drop_rounded,
            const Color(0xFF00BCD4),
            const Color(0xFF00BCD4).withOpacity(0.1),
          ),
          const Divider(height: 30, thickness: 1, color: Colors.black12),
          _buildActivityItem(
            "Light cycle adjusted",
            "1 hour ago",
            Icons.lightbulb_rounded,
            const Color(0xFFE91E63),
            const Color(0xFFE91E63).withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color iconColor, Color bgColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: bgColor,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF23303B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {String? actionText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (actionText != null) 
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, 
                backgroundColor: Colors.transparent, 
                builder: (context) => AdvancedDataSheet(
                  currentPh: double.tryParse(phLevel) ?? 0.0, 
                  currentTemp: _tempValue, 
                  currentAirflow: _airflowValue, 
                  currentLight: _lightValue, 
                  nutriN: _nutriN, 
                  nutriP: _nutriP, 
                  nutriK: _nutriK, 
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
              child: Text(
                'View All', 
                style: TextStyle(
                  color: Color(0xFF2D5A27), 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 95,
      decoration: BoxDecoration(color: isDark ? const Color(0xFF181818) : Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_filled, "Home"),
          _buildNavItem(1, Icons.bar_chart_rounded, "Analytics"),
          _buildNavItem(2, Icons.science_rounded, "Harvesting"),
          _buildNavItem(3, Icons.history_rounded, "History"),
          _buildNavItem(4, Icons.settings_rounded, "Settings"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool active = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFF2D5A27) : Colors.grey),
          Text(label, style: TextStyle(color: active ? const Color(0xFF2D5A27) : Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActiveBadge(bool isUnregistered) {
    bool active = !isUnregistered && isServerOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? Colors.greenAccent : Colors.red)),
      child: Text(active ? "ACTIVE" : (isUnregistered ? "UNLINKED" : "OFFLINE"), style: TextStyle(color: active ? Colors.greenAccent : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // 🔥 5. WARNING REGISTER (DIPERBARUI JADI TOMBOL SHORTCUT JIR!)
  Widget _buildRegisterWarning() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        // Langsung lompat nyalain kamera scanner bray!
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const LoginQrScreen())
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.amber.shade700)
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700), 
            const SizedBox(width: 10), 
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDark ? Colors.white : Colors.black87, 
                    fontFamily: 'Inter' // Samain sama tema utama lu
                  ),
                  children: const [
                    TextSpan(text: "Alat belum tertaut! Scan QR "),
                    TextSpan(
                      text: "di sini.",
                      style: TextStyle(
                        color: Colors.blueAccent, // Warna link biru nyala
                        decoration: TextDecoration.underline, // Kasih garis bawah biar rill kayak link
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }
} 

class CustomFloatingLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return Offset(scaffoldGeometry.scaffoldSize.width - 85, scaffoldGeometry.scaffoldSize.height - 200);
  }
}