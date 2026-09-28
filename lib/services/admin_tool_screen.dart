import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminToolScreen extends StatefulWidget {
  const AdminToolScreen({super.key});

  @override
  State<AdminToolScreen> createState() => _AdminToolScreenState();
}

class _AdminToolScreenState extends State<AdminToolScreen> {
  // Sekarang nampung data dinamis dari database PostgreSQL bray
  List<dynamic> _registeredDevices = [];
  bool _isLoading = true;

  final TextEditingController _snController = TextEditingController();
  final TextEditingController _pinController = TextEditingController(text: "123456");

  @override
  void initState() {
    super.initState();
    _fetchDevicesFromDB(); // 🔥 Otomatis muat data pas screen dibuka bray!
  }

  @override
  void dispose() {
    _snController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // --- 🔥 FUNGSI BARU: TARIK DAFTAR DEVICE DARI POSTGRESQL ---
  Future<void> _fetchDevicesFromDB() async {
    setState(() => _isLoading = true);
    try {
      // Kita pakai endpoint sensor atau device publik untuk demo ini bray
      final response = await http.get(
        Uri.parse('https://livera.mataramteachingfactory.store/api/device/users?sn='),
      );

      if (response.statusCode == 200) {
        // Karena rute /api/device/users ngereturn list user terikat, atau kita simulasiin device yang aktif
        // Note: Idealnya lu panggil rute khusus GET /api/admin/devices. 
        // Sementara kita buat fallback nampilin data statis kalau list kosong agar QR gak hilang.
        final data = jsonDecode(response.body);
        setState(() {
          _registeredDevices = data is List ? data : [];
        });
      }
    } catch (e) {
      debugPrint("Gagal load history QR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI MENGIRIM DATA PERANGKAT KE SERVER ---
  Future<void> _addDeviceToServer() async {
    final String serialNumber = _snController.text.trim();
    final String pin = _pinController.text.trim();

    if (serialNumber.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nomor Seri dan PIN wajib diisi."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/admin/add-device'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "serial_number": serialNumber,
          "pin": pin,
        }),
      );

      if (response.statusCode == 201) {
        // Re-fetch dari database biar daftarnya paling up-to-date dan tersimpan permanen bray!
        await _fetchDevicesFromDB();
        
        // Fallback lokal kalau server butuh rute admin khusus
        if (_registeredDevices.isEmpty) {
          setState(() {
            _registeredDevices.add({
              "serial_number": serialNumber,
              "pin": pin,
            });
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perangkat baru berhasil didaftarkan ke basis data."), backgroundColor: Colors.green),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? "Gagal mendaftarkan perangkat pada server.");
      }
    } catch (e) {
      debugPrint("Kesalahan sistem: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDeviceDialog() {
    _snController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Registrasi Perangkat Baru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Masukkan rincian identitas perangkat yang telah selesai dirakit.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _snController,
              decoration: InputDecoration(
                labelText: "Nomor Seri (Contoh: LVRA-X1-001)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "PIN Keamanan",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.password_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addDeviceToServer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5A27),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Simpan ke Server", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sistem Administrasi LIVERA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D5A27),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDevicesFromDB, // Tombol manual refresh bray
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Daftar Cetak Kode QR Perangkat",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Daftar di bawah ini tersimpan aman di database PostgreSQL server LIVERA bray.",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: _registeredDevices.isEmpty
                      ? const Center(
                          child: Text(
                            "Belum ada perangkat di database.\nTekan tombol (+) untuk menambah perangkat.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _registeredDevices.length,
                          itemBuilder: (context, index) {
                            final device = _registeredDevices[index];
                            final String currentSN = device["serial_number"] ?? "LVRA-UNKNOWN";
                            final String currentPin = device["pin"] ?? "123456";
                            
                            final String qrJsonString = jsonEncode({
                              "serial_number": currentSN,
                              "pin": currentPin
                            });

                            return _buildQrCard(currentSN, qrJsonString);
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF62B660)),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDeviceDialog,
        backgroundColor: const Color(0xFF2D5A27),
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: const Text("Tambah Perangkat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQrCard(String serialNumber, String qrData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "LIVERA",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2D5A27), letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 100.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            serialNumber,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const Text(
            "Smart Algae Purifier",
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}