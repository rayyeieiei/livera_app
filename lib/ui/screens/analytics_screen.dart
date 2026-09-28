import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart'; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; 

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  
  // --- STATE DATA ---
  List<double> co2History = [];
  List<double> biomassHistory = [];
  List<double> tempHistory = [];
  double airHealthScore = 0;
  double totalOxygenGenerated = 0.0;
  
  bool _isLoading = true;
  bool _isServerOnline = true; // 🔥 Nandaian Server Mati/Hidup

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;
    final token = userProvider.token;

    try {
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/sensor/history?sn=$sn'),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> logs = jsonDecode(response.body);
        
        if (logs.isNotEmpty) {
          logs = logs.reversed.toList();
          if (mounted) {
            setState(() {
              co2History = logs.map((l) => ((l['co2'] ?? 0) as num).toDouble()).toList();
              biomassHistory = logs.map((l) => ((l['biomass'] ?? 0) as num).toDouble()).toList();
              tempHistory = logs.map((l) => ((l['temperature'] ?? 0) as num).toDouble()).toList();
              
              double lastCO2 = co2History.isNotEmpty ? co2History.last : 0.0;
              airHealthScore = ((1200 - lastCO2) / 8).clamp(0.0, 100.0);
              totalOxygenGenerated = biomassHistory.isNotEmpty ? biomassHistory.last * 12.5 : 0.0; // Angka simulasi laporan oksigen
              
              _isServerOnline = true;
              _isLoading = false;
            });
          }
          return; 
        }
      } else {
        throw Exception("Server ngerespon tapi error (Bukan 200)");
      }
    } catch (e) {
      debugPrint("❌ Server Mati atau Gagal Tarik Data: $e");
      
      // 🔥 JIKA SERVER MATI: Data dikosongin, grafiknya dibikin rata 0, UI ditandai Offline
      if (mounted) {
        setState(() {
          co2History = [0, 0, 0, 0, 0, 0, 0];
          biomassHistory = [0, 0, 0, 0, 0, 0, 0];
          tempHistory = [0, 0, 0, 0, 0, 0, 0];
          airHealthScore = 0.0;
          totalOxygenGenerated = 0.0;
          
          _isServerOnline = false;
          _isLoading = false;
        });

        // 🔥 Munculin Notif Pop-up Server Mati dari bawah UI (Snack-bar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Sistem Offline. Gagal mengambil riwayat analitis terbaru.", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFECFDF5),
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFFF0FDFA)
            ],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            
            // 🔥 Indikator Merah Kalo Server Mati (Banner Atas)
            if (!_isServerOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFFEF4444),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text("Lost Connection to LIVERA Server", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : RefreshIndicator(
                    onRefresh: _fetchAnalyticsData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Screenshot(
                        controller: screenshotController,
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAirHealthCard(),
                              const SizedBox(height: 20),
                              _buildChartCard('CO2 Concentration (Current)', const Color(0xFF10B981), co2History),
                              const SizedBox(height: 20),
                              _buildChartCard('Biomass Density (g/L)', const Color(0xFFF59E0B), biomassHistory),
                              const SizedBox(height: 20),
                              _buildChartCard('Temperature Stability (°C)', const Color(0xFF3B82F6), tempHistory),
                              const SizedBox(height: 20),
                              _buildOxygenReportCard(context),
                            ],
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

  // --- KOMPONEN: APPBAR ---
  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16), // Fix UI nubruk baterai
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.bar_chart_rounded, color: Color(0xFF1F2937), size: 24),
          const Text('LIVERA Analytics', style: TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          IconButton(onPressed: _fetchAnalyticsData, icon: const Icon(Icons.sync, color: Color(0xFF10B981))),
        ],
      ),
    );
  }

  // --- KOMPONEN: AIR HEALTH SCORE ---
  Widget _buildAirHealthCard() {
    String status = _isServerOnline ? (airHealthScore > 80 ? "Excellent" : (airHealthScore < 50 ? "Poor" : "Good")) : "Offline";
    String displayScore = _isServerOnline ? airHealthScore.toStringAsFixed(0) : "--";

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Air Health Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 120, height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: const Size(120, 120), painter: DashedCirclePainter(isOffline: !_isServerOnline)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(displayScore, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _isServerOnline ? const Color(0xFF1F2937) : Colors.grey)),
                      Text(status, style: TextStyle(fontSize: 12, color: _isServerOnline ? const Color(0xFF6B7280) : Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: _isServerOnline 
                  ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF34D399)])
                  : const LinearGradient(colors: [Colors.grey, Colors.grey]),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poor', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              Text('Excellent', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN: CHART CARD ---
  Widget _buildChartCard(String title, Color lineColor, List<double> dataPoints) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: LineChartPainter(
                lineColor: _isServerOnline ? lineColor : Colors.grey.shade400, // Warna grafik jadi abu kalo offline
                data: dataPoints,
                isOffline: !_isServerOnline
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_isServerOnline ? 'Recent history from PostgreSQL' : 'Data unavailable - System Offline', style: TextStyle(fontSize: 10, color: _isServerOnline ? const Color(0xFF9CA3AF) : Colors.red)),
        ],
      ),
    );
  }

  // --- KOMPONEN: OXYGEN REPORT ---
  Widget _buildOxygenReportCard(BuildContext context) {
    String displayO2 = _isServerOnline ? '${totalOxygenGenerated.toStringAsFixed(1)}L' : '--';

    return Stack(
      children: [
        _buildGlassCard(
          child: Column(
            children: [
              const Align(alignment: Alignment.topLeft, child: Text('Oxygen Production Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))),
              const SizedBox(height: 16),
              Icon(Icons.air, color: _isServerOnline ? const Color(0xFF10B981) : Colors.grey, size: 40),
              const SizedBox(height: 16),
              Text(displayO2, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _isServerOnline ? const Color(0xFF1F2937) : Colors.grey)),
              const Text('Total O2 Generated based on Algae Biomass', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatSmall(_isServerOnline ? 'Real-time' : 'Offline', 'System Mode', isPositive: _isServerOnline),
                  _buildStatSmall(_isServerOnline ? 'Active' : 'Disconnected', 'PostgreSQL Sync', isPositive: _isServerOnline),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Positioned(
          bottom: 10, right: 10,
          child: FloatingActionButton.small(
            onPressed: _isServerOnline ? () => _showExportDialog(context) : null, // Gak bisa export PDF kalo server mati
            backgroundColor: _isServerOnline ? const Color(0xFF10B981) : Colors.grey,
            child: const Icon(Icons.download, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStatSmall(String val, String label, {bool isPositive = false}) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: child,
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Download Analytics Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF10B981)),
              title: const Text('Export as PNG Image'),
              onTap: () { Navigator.pop(context); _exportFile(format: 'png'); },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF10B981)),
              title: const Text('Export as PDF Document'),
              onTap: () { Navigator.pop(context); _exportFile(format: 'pdf'); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportFile({required String format}) async {
    final Uint8List? imageBytes = await screenshotController.capture();
    if (imageBytes != null) {
      if (format == 'png') {
        await Printing.sharePdf(bytes: imageBytes, filename: 'LIVERA_Report.png');
      } else {
        final pdf = pw.Document();
        final image = pw.MemoryImage(imageBytes);
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(image)),
        ));
        await Printing.layoutPdf(onLayout: (format) => pdf.save());
      }
    }
  }
}

class LineChartPainter extends CustomPainter {
  final Color lineColor;
  final List<double> data;
  final bool isOffline;
  LineChartPainter({required this.lineColor, required this.data, this.isOffline = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return; 
    
    final paintLine = Paint()..color = lineColor..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintFill = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)]).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    double maxVal = isOffline ? 10.0 : data.reduce(max);
    double minVal = isOffline ? 0.0 : data.reduce(min);
    
    // 🔥 FIX: Jika data flat (nilainya sama semua), beri padding atas bawah agar grafik digambar di tengah
    if (maxVal == minVal) {
      maxVal += 10;
      minVal -= 10;
    } 

    final path = Path();
    double stepX = size.width / (data.length - 1); 

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double ratio = (data[i] - minVal) / (maxVal - minVal);
      double y = isOffline 
          ? size.height / 2 
          : size.height - (ratio * size.height * 0.7) - (size.height * 0.15);
      
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }

    canvas.drawPath(path, paintLine);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paintFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashedCirclePainter extends CustomPainter {
  final bool isOffline;
  DashedCirclePainter({this.isOffline = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = isOffline ? Colors.grey.shade400 : const Color(0xFF10B981)..strokeWidth = 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    double radius = size.width / 2;
    Offset center = Offset(radius, radius);
    double dashWidth = 0.3;
    double dashSpace = 0.2;
    double currentAngle = -pi / 2;
    while (currentAngle < 2 * pi - pi / 2) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, dashWidth, false, paint);
      currentAngle += dashWidth + dashSpace;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}