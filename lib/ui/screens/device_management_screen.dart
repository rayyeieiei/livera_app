import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/main.dart'; 
import 'login_screen.dart'; 

class DeviceManagementScreen extends StatefulWidget {
  final String serialNumber; 

  const DeviceManagementScreen({super.key, required this.serialNumber});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  bool _isSyncing = false;

  final Color liveraGreen = const Color(0xFF2D5A27);
  final Color textDark = const Color(0xFF0B2A12);
  final Color textGrey = const Color(0xFF7B8B7A);
  final Color cardBg = Colors.white;

  // --- API: AMBIL DAFTAR USER BESERTA TOKEN JIR! ---
  Future<List<dynamic>> _fetchLinkedUsers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Ganti rute sesuai yang ada di Golang lu
    final url = Uri.parse('https://livera.mataramteachingfactory.store/api/device/members?sn=${widget.serialNumber}');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${userProvider.token}"}, // WAJIB ADA TOKEN
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal ambil data user');
    }
  }

  // --- API: NGE-KICK MEMBER (KHUSUS OWNER) ---
  Future<void> _handleKickUser(int targetUserId, String email) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Konfirmasi dulu sebelum nendang orang
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Tendang $email?", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: const Text("User ini gak bakal bisa ngontrol alat ini lagi sebelum pairing ulang."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4949)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Tendang", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      final response = await http.delete(
        Uri.parse('https://livera.mataramteachingfactory.store/api/device/kick'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${userProvider.token}"
        },
        body: jsonEncode({
          "serial_number": widget.serialNumber,
          "target_user_id": targetUserId
        }),
      );

      if (response.statusCode == 200) {
        // Kalo sukses nendang, refresh listnya
        setState(() {}); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member berhasil ditendang!"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal nendang: ${jsonDecode(response.body)['error']}")));
      }
    } catch (e) {
      debugPrint("Gagal kick jir: $e");
    }
  }

  // --- LOGIC: SYNC ---
  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isSyncing = false);
    setState(() {}); // Triger refresh
  }

  // --- LOGIC: DISCONNECT DIRI SENDIRI ---
  void _handleDisconnect() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('dm_btn_disconnect'.tr(), style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Text('dm_disconnect_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('dm_cancel'.tr())),
          ElevatedButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              try {
                final response = await http.post(
                  Uri.parse('https://livera.mataramteachingfactory.store/api/device/unpair'),
                  headers: {"Authorization": "Bearer ${userProvider.token}"},
                  body: jsonEncode({"serial_number": widget.serialNumber}), // Wajib kirim SN
                );

                if (response.statusCode == 200) {
                  userProvider.updateSerialNumber("");
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('saved_serial');
                  if (mounted) {
                    Navigator.pop(context); 
                    Navigator.pop(context); 
                  }
                }
              } catch (e) {
                debugPrint("Gagal unpair jir: $e");
              }
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4949)),
            child: Text('dm_btn_disconnect'.tr(), style: const TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('dm_title'.tr(), style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('dm_linked_header'.tr(), style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _buildSectionCard(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchLinkedUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Gak ada user terdeteksi", style: TextStyle(color: textGrey)));
                }

                // Cek apakah user yang lagi login ini adalah OWNER
                bool amIOwner = snapshot.data!.any((user) => user['email'] == userProvider.email && user['role'] == 'owner');

                return Column(
                  children: snapshot.data!.map((user) {
                    bool isMe = user['email'] == userProvider.email;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildSubDeviceItem(
                        user['user_id'] ?? 0,
                        user['email'] ?? 'User', 
                        user['role'] ?? 'member', // Tampilin rolenya asli dari DB
                        isMe,
                        amIOwner // Kirim info hak akses
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          
          _buildSectionCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('dm_hw_model_label'.tr(), style: TextStyle(color: textDark, fontWeight: FontWeight.w500)),
                const Text('LIVERA Pro-Edition (12L)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SECURITY NOTICE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F3EA), 
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: liveraGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'dm_security_notice'.tr(),
                    style: TextStyle(color: textDark.withOpacity(0.8), fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _handleSync,
            icon: _isSyncing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync_rounded),
            label: Text(_isSyncing ? 'Syncing...' : 'dm_btn_sync'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: liveraGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _handleDisconnect,
            icon: const Icon(Icons.link_off_rounded),
            label: Text('dm_btn_disconnect'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF4949),
              side: const BorderSide(color: Color(0xFFFF4949), width: 1.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _buildSubDeviceItem(int targetUserId, String email, String role, bool isMe, bool amIOwner) {
    // Format tulisan role biar kapital (Owner / Member)
    String displayRole = role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : 'Member';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? liveraGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: isMe ? liveraGreen : Colors.grey, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email, style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
              Text(isMe ? "$displayRole (You)" : displayRole, style: TextStyle(color: textGrey, fontSize: 12)),
            ],
          ),
        ),
        
        // 🔥 LOGIKA KICK: Tombol Hapus nongol cuma buat Owner, dan Owner gak bisa nendang dirinya sendiri
        if (amIOwner && !isMe)
          IconButton(
            icon: const Icon(Icons.person_remove_rounded, color: Color(0xFFFF4949), size: 22),
            onPressed: () => _handleKickUser(targetUserId, email),
          )
        else if (isMe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F3EA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('dm_connected'.tr(), style: TextStyle(color: liveraGreen, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}