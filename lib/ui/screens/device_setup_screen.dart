import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; // Buat UserProvider lu

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  String deviceName = "Loading...";
  bool isConnected = false;
  bool _isLoading = true;
  
  // --- STATE VARIABLE UNTUK AKURASI MULTI-USER ---
  List<dynamic> _deviceMembers = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDeviceInfo();
      _fetchDeviceMembers(); // 🔥 Tarik data multi-user pendamping bray!
    });
  }

  // --- API: AMBIL INFO ALAT DARI GO ---
  Future<void> _fetchDeviceInfo() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;

    if (sn.isEmpty || sn == "NONE") {
      setState(() {
        deviceName = "Belum ada alat terpasang";
        isConnected = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/device/info?sn=$sn'),
        headers: {"Authorization": "Bearer ${userProvider.token}"},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          deviceName = data['device_name'] ?? "LIVERA Smart Purifier";
          isConnected = true; 
          _isLoading = false;
        });
      } else {
        setState(() {
          deviceName = "Alat Tidak Dikenal Sistem";
          isConnected = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Gagal narik info alat dari server: $e");
      setState(() {
        deviceName = "Server Offline / Gangguan";
        isConnected = false;
        _isLoading = false;
      });
    }
  }

  // --- 🔥 API TAMBAHAN: FETCH MULTI-USER HP/EMAIL TERHUBUNG DARI GO ---
  Future<void> _fetchDeviceMembers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;
    final token = userProvider.token;

    if (sn.isEmpty || sn == "NONE") {
      setState(() => _isLoadingMembers = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/device/members?sn=$sn'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _deviceMembers = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("❌ Gagal sinkronisasi data user terhubung: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  // --- 🔥 API TAMBAHAN: CABUT AKSES HP PENGGUNA LAIN VIA GO ---
  Future<void> _kickMember(int targetUserId, String email) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sn = userProvider.serialNumber;
    final token = userProvider.token;

    try {
      final response = await http.delete(
        Uri.parse('https://livera.mataramteachingfactory.store/api/device/kick'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "serial_number": sn,
          "target_user_id": targetUserId,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Akses milik $email resmi dicabut!"), backgroundColor: Colors.green),
          );
        }
        _fetchDeviceMembers(); // Auto refresh daftar list HP bray!
      } else {
        _showErrorSnackBar("Gagal mencabut hak akses pengguna!");
      }
    } catch (e) {
      debugPrint("❌ Gagal kick member: $e");
      _showErrorSnackBar("Masalah jaringan cloud TeFa!");
    }
  }

  // --- API: UPDATE NAMA ALAT KE GO + SINKRONISASI GLOBAL ---
  Future<void> _updateDeviceName(String newName) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A27))),
    );

    try {
      final response = await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/device/update-name'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${userProvider.token}"
        },
        body: jsonEncode({
          "serial_number": userProvider.serialNumber,
          "device_name": newName,
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading progress bray

      if (response.statusCode == 200) {
        setState(() {
          deviceName = newName;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🎉 Sukses! Nama bioreaktor LIVERA resmi diperbarui."), 
              backgroundColor: Color(0xFF2D5A27),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _showErrorSnackBar("Gagal memperbarui nama, status: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("❌ Gagal total update nama device: $e");
      _showErrorSnackBar("Terjadi kesalahan jaringan: $e");
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F1720)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('dev_title'.tr(), 
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F1720), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A27)))
        : ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _buildStatusCard(isDark),
              const SizedBox(height: 20),
              _buildSharedUsersCard(isDark), // 🔥 KOTAK MULTI-USER ALL IN ONE PLACE JIR!
              const SizedBox(height: 20),
              _buildCalibrationCard(isDark),
            ],
          ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconCircle(Icons.wifi_rounded, const Color(0xFF2D5A27)),
              const SizedBox(width: 16),
              Text('dev_status_section'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F5F7), 
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text('dev_connected_label'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: _showEditNameDialog,
                      child: const Icon(Icons.edit_note_rounded, size: 26, color: Color(0xFF2D5A27)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: isConnected ? const Color(0xFF34C759) : Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(isConnected ? 'Connected to Server' : 'Disconnected', style: TextStyle(color: isConnected ? const Color(0xFF34C759) : Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildButton("Configure WiFi Network", const Color(0xFF2D5A27), Colors.white),
        ],
      ),
    );
  }

  // --- 🔥 CARD MANAGEMENT AKURASI MULTI-USER HP & EMAIL ---
  Widget _buildSharedUsersCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconCircle(Icons.supervisor_account_rounded, const Color(0xFF2D5A27)),
              const SizedBox(width: 16),
              const Text("Pengguna Multi-Akses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Daftar email & device HP lain yang diizinkan memantau reaktor LIVERA ini secara real-time.",
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 20),
          
          _isLoadingMembers
              ? const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: Color(0xFF2D5A27))))
              : _deviceMembers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text("Hanya HP Anda yang tertaut", style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(), 
                      itemCount: _deviceMembers.length,
                      itemBuilder: (context, index) {
                        final member = _deviceMembers[index];
                        bool isOwner = member['role'] == 'owner';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              isOwner ? Icons.admin_panel_settings_rounded : Icons.phone_android_rounded,
                              color: isOwner ? const Color(0xFF16A34A) : Colors.blueGrey,
                              size: 22,
                            ),
                            title: Text(
                              member['email'] ?? "User Terhubung",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              isOwner ? "Pemilik Alat" : "Akses Anggota",
                              style: TextStyle(fontSize: 11, color: isOwner ? const Color(0xFF16A34A) : Colors.grey),
                            ),
                            trailing: isOwner
                                ? const SizedBox.shrink()
                                : IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _showKickConfirmationDialog(member['user_id'], member['email']),
                                  ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconCircle(Icons.show_chart_rounded, const Color(0xFF2D5A27)),
              const SizedBox(width: 16),
              Text('dev_calib_section'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: CalibrationChartPainter(), 
            ),
          ),
          
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('dev_calib_status_label'.tr(), style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('dev_calib_status_complete'.tr(), style: const TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildButton("dev_btn_recalibrate".tr(), const Color(0xFF2D5A27).withOpacity(0.1), const Color(0xFF2D5A27)),
        ],
      ),
    );
  }

  void _showKickConfirmationDialog(int userId, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cabut Hak Akses?"),
        content: Text("Apakah Anda yakin ingin memutuskan koneksi akun $email dari alat LIVERA ini?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _kickMember(userId, email);
            }, 
            child: const Text("Ya, Tendang", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    TextEditingController controller = TextEditingController(text: deviceName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Device Name", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller, 
          decoration: InputDecoration(
            hintText: "Contoh: LIVERA Kamar Tidur",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
          )
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A27)),
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _updateDeviceName(controller.text);
              }
            }, 
            child: const Text("Simpan", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildButton(String text, Color bg, Color textCol) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fitur ini aktif setelah konek via Bluetooth ke ESP32!"), behavior: SnackBarBehavior.floating)
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
        child: Text(text, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

class CalibrationChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = Colors.grey.withOpacity(0.2)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      double y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.8, size.height * 0.42),
      Offset(size.width, size.height * 0.4),
    ];
    final paintDashed = Paint()..color = Colors.green.withOpacity(0.5)..strokeWidth = 2..style = PaintingStyle.stroke;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i+1], paintDashed);
    }
    final paintLine = Paint()..color = const Color(0xFF2D5A27)..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i+1], paintLine);
    }
    final paintDotBorder = Paint()..color = const Color(0xFF2D5A27);
    final paintDotInner = Paint()..color = Colors.white;
    for (var point in points) {
      canvas.drawCircle(point, 6, paintDotBorder);
      canvas.drawCircle(point, 3, paintDotInner);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}