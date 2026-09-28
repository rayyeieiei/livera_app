import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; // Buat ambil UserProvider lu

class NutrientScreen extends StatefulWidget {
  const NutrientScreen({super.key});

  @override
  State<NutrientScreen> createState() => _NutrientScreenState();
}

class _NutrientScreenState extends State<NutrientScreen> {
  // --- STATE VARIABLES (Synced with PostgreSQL) ---
  bool _isManagedMode = true;
  int _nutrientLevel = 0;
  int _n = 0, _p = 0, _k = 0;
  DateTime _lastInject = DateTime.now();
  Timer? _timer;
  bool _isLoading = true;

  // --- API LOGIC: FETCH DATA NUTRISI AMAN ANTI-LOADING ABADI JIR ---
  Future<void> _fetchNutrientData() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;

    try {
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/control?sn=$sn'),
      ).timeout(const Duration(seconds: 4)); // Kasih timeout biar gak stuck bray

      print("📡 Nutrient Server Response: ${response.statusCode}");

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _nutrientLevel = data['nutri_level'] ?? 0;
          _n = data['nutri_n'] ?? 0;
          _p = data['nutri_p'] ?? 0;
          _k = data['nutri_k'] ?? 0;
          _isManagedMode = data['managed_mode'] ?? true;
          _lastInject = DateTime.tryParse(data['last_nutri_inject'] ?? '') ?? DateTime.now();
        });
      } else {
        print("❌ Server Balikin Eror di Nutrisi: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Gagal total sinkron nutrisi: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- API LOGIC: INJECT / UPDATE ---
  Future<void> _updateNutrient(int level, bool isManaged) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/control/update'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${userProvider.token}"
        },
        body: jsonEncode({
          "serial_number": userProvider.serialNumber,
          "nutri_level": level, // 100 kalo inject now
          "managed_mode": isManaged,
        }),
      );
      _fetchNutrientData(); // Refresh data abis update
    } catch (e) {
      debugPrint("Gagal update nutrisi: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNutrientData();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) => _fetchNutrientData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _calculateDaysLeft() {
    final nextInject = _lastInject.add(const Duration(days: 30));
    final difference = nextInject.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
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
                        _buildMainNutrientCard(),
                        const SizedBox(height: 32),
                        _buildManualControlSection(),
                        const SizedBox(height: 32),
                        _buildManagedModeToggle(),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111214), size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text('nutr_title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMainNutrientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F1A1D20), blurRadius: 32, offset: Offset(0, 12))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: Color(0xFFE8F7FF), shape: BoxShape.circle),
                child: const Icon(Icons.science_rounded, color: Color(0xFF16A34A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE6FFEA), borderRadius: BorderRadius.circular(16)),
                child: Text('nutr_status_stable'.tr(), style: const TextStyle(color: Color(0xFF1EC070), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_nutrientLevel', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, height: 1)),
              const Padding(padding: EdgeInsets.only(top: 8, left: 4), child: Text('%', style: TextStyle(fontSize: 24, color: Colors.grey))),
            ],
          ),
          const SizedBox(height: 8),
          Text('nutr_overall_level'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          
          // 🔥 DYNAMIC NPK BAR (Sesuai data dari Go)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(flex: _n == 0 ? 1 : _n, child: Container(height: 12, color: const Color(0xFF16A34A))), 
                const SizedBox(width: 2),
                Expanded(flex: _p == 0 ? 1 : _p, child: Container(height: 12, color: const Color(0xFF111214))), 
                const SizedBox(width: 2),
                Expanded(flex: _k == 0 ? 1 : _k, child: Container(height: 12, color: const Color(0xFFCBD5E1))), 
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendRow(),
        ],
      ),
    );
  }

  Widget _buildLegendRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('Nitrogen ($_n%)', const Color(0xFF16A34A)),
            _buildLegendItem('Phosphorus ($_p%)', const Color(0xFF111214)),
          ],
        ),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: _buildLegendItem('Potassium ($_k%)', const Color(0xFFCBD5E1))),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color dotColor) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildManualControlSection() {
    int daysLeft = _calculateDaysLeft();
    
    // FORMAT TANGGALNYA BIAR CANTIK JIR (Contoh: 09 June 2026)
    String lastInjectFormatted = DateFormat('dd MMMM yyyy').format(_lastInject);

    return Opacity(
      opacity: _isManagedMode ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('nutr_manual_control'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFE9FFF0), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('nutr_next_injection'.tr(), 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 🔥 INI DIA TIMELINE REFILL REAL-TIME NYA COKK!
                      Text('Terakhir Refill: $lastInjectFormatted', 
                        style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), 
                Text('$daysLeft ${'days'.tr()}', 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),   
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isManagedMode ? null : () {
                // Pas diklik, ngirim level 100 ke Go dan merestart waktu last_nutri_inject jadi SEKARANG!
                _updateNutrient(100, _isManagedMode);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('🎉 NPK Refilled! Timeline reset to 30 Days.'), 
                  backgroundColor: Color(0xFF16A34A)
                ));
              },
              icon: const Icon(Icons.colorize_rounded, color: Colors.white),
              label: Text('nutr_btn_inject'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagedModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('nutr_managed_mode'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('AI-calculated nutrient dosage', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Switch.adaptive(
          value: _isManagedMode,
          activeColor: const Color(0xFF16A34A),
          onChanged: (val) {
            setState(() => _isManagedMode = val);
            _updateNutrient(_nutrientLevel, val);
          },
        ),
      ],
    );
  }
}