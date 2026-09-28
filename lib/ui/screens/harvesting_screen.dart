import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:livera_app/main.dart'; // Buat ambil UserProvider
import 'package:livera_app/ui/screens/harvesting_guide_screen.dart'; 

class HarvestingScreen extends StatefulWidget {
  const HarvestingScreen({super.key});

  @override
  State<HarvestingScreen> createState() => _HarvestingScreenState();
}

class _HarvestingScreenState extends State<HarvestingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bubbleController;
  Timer? _timer;
  
  // --- STATE VARIABLE UNTUK DATA REAL-TIME ---
  double _biomassDensity = 0.0;     // g/L (dari API sensor)
  double _nutrientLevel = 0.0;      // 0.0 - 1.0 (dari API control)
  bool _isLoading = true;
  bool _isServerOnline = true;      // 🔥 State buat nandaian Server idup/mati

  // --- Konstanta Reaktor ---
  final double targetBiomass = 3.5; // g/L (Target maksimal panen)
  final double reactorVolume = 5.0; // Liter (Volume air LIVERA)

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fetchHarvestData();
    // Refresh otomatis tiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchHarvestData());
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchHarvestData() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;
    
    // Kalau belum register device, langsung anggap offline
    if (sn.isEmpty || sn == "NONE") {
       if (mounted) {
         setState(() {
           _biomassDensity = 0.0;
           _nutrientLevel = 0.0;
           _isServerOnline = false;
           _isLoading = false;
         });
       }
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
            _isServerOnline = true;
            _biomassDensity = (data['biomass'] ?? 0.0).toDouble();
            
            double rawNutri = (data['nutri_level'] ?? 0).toDouble();
            _nutrientLevel = (rawNutri / 100).clamp(0.0, 1.0);
            
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Server ngerespon error");
      }
    } catch (e) {
      debugPrint("❌ Gagal fetch data Harvesting: $e");
      if (mounted) {
        setState(() {
          _biomassDensity = 0.0;
          _nutrientLevel = 0.0;
          _isServerOnline = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF0F1720);

    // --- KALKULASI PINTAR BERDASARKAN DATA REAL-TIME
    double waterLevel = _biomassDensity > 0 
        ? (_biomassDensity / targetBiomass).clamp(0.0, 1.0) 
        : 0.0;

    int readinessPercent = _biomassDensity > 0 
        ? ((_biomassDensity / targetBiomass) * 100).toInt().clamp(0, 100) 
        : 0;

    int estimatedYield = (_biomassDensity * reactorVolume * 0.2 * 100).toInt();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                if (!_isServerOnline)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 12),
                        Expanded(child: Text("Sistem Offline. Gagal terhubung ke sensor reaktor.", style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),

                Text(
                  'harv_status_title'.tr(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: titleColor, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 8),
                Text(
                  'harv_status_desc'.tr(),
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 32),

                _buildSimpleReactorCard(cardBg, waterLevel),

                const SizedBox(height: 24),

               Row(
                  children: [
                    _buildLiteStatCard(
                      _isServerOnline ? '$readinessPercent%' : '--', 
                      'harv_readiness_label'.tr(), 
                      _isServerOnline ? const Color(0xFF22C55E) : Colors.grey, 
                      cardBg
                    ),
                    const SizedBox(width: 16),
                    _buildLiteStatCard(
                      _isServerOnline ? '${estimatedYield}g' : '--', 
                      'harv_yield_label'.tr(), 
                      _isServerOnline ? titleColor : Colors.grey, 
                      cardBg
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildLitePillTracker(cardBg),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: (_isServerOnline && readinessPercent > 80) ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HarvestingGuideScreen()),
                    ) : null, // Tombol dikunci kalo server mati ATAU alga belom siap
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text(
                      !_isServerOnline ? 'Sistem Offline' : (readinessPercent > 80 ? 'harv_btn_start_guide'.tr() : 'Algae Belum Siap Panen'),
                      style: TextStyle(
                        color: (isDark || readinessPercent <= 80 || !_isServerOnline) ? const Color(0xFF9CA3AF) : Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSimpleReactorCard(Color cardBg, double waterLevel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text('harv_density_status'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),

          SizedBox(
            height: 250,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.7),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutBack,
                      width: 87, 
                      height: _isServerOnline ? (194 * waterLevel).clamp(20.0, 200.0) : 0.0, // 🔥 AIRNYA ILANG KALO OFFLINE
                      decoration: BoxDecoration(
                        color: !_isServerOnline ? Colors.transparent : null,
                        gradient: _isServerOnline ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF34D399), Color(0xFF059669)],
                        ) : null,
                      ),
                      child: _isServerOnline ? AnimatedBuilder(
                        animation: _bubbleController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: BubblePainter(animationValue: _bubbleController.value),
                          );
                        },
                      ) : const SizedBox(), // Gelembung mati kalo offline
                    ),
                  ),
                ),

                Image.asset(
                  'assets/images/reactor_glass_empty.webp',
                  height: 230,
                  width: 140, 
                  fit: BoxFit.contain,
                ),
                
                if (waterLevel > 0.7 && _isServerOnline)
                  Positioned(
                    right: 20,
                    top: 20,
                    child: _buildHighDensityBadge(cardBg),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isServerOnline ? const Color(0xFFF0FDF4) : Colors.grey.shade200, // Warna berubah abu kalo mati
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isServerOnline ? '${_biomassDensity.toStringAsFixed(2)} g/L' : '-- g/L',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isServerOnline ? const Color(0xFF16A34A) : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighDensityBadge(Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Text(
        'harv_density_high'.tr(),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
      ),
    );
  }

  Widget _buildLiteStatCard(String val, String label, Color col, Color cardBg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(color: col, fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLitePillTracker(Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('harv_nutrient_tracker'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.water_drop_outlined, color: _isServerOnline ? const Color(0xFF22C55E) : Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _isServerOnline ? _nutrientLevel : 0.0, // Progress bar kosong kalo mati
              backgroundColor: const Color(0xFFF3F4F6),
              color: _isServerOnline ? const Color(0xFF22C55E) : Colors.grey,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isServerOnline ? 'harv_nutrient_desc'.tr(args: ['${(_nutrientLevel * 100).toInt()}%']) : 'Nutrient data unavailable', 
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)
          ),
        ],
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  final double animationValue;
  BubblePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    final random = Random(42);
    for (int i = 0; i < 12; i++) {
      double x = random.nextDouble() * size.width;
      double y = ((1.0 - (animationValue + random.nextDouble()) % 1.0) * size.height);
      double radius = random.nextDouble() * 3 + 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}