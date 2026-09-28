import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'login_screen.dart';
import './device_management_screen.dart';
import '../../services/admin_tool_screen.dart'; 
import 'subscription.plan.screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNotificationOn = true;
  bool _isProcessing = false; 
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  final Color liveraGreen = const Color(0xFF62B660);
  final Color textDark = const Color(0xFF072009);
  final Color textGrey = const Color(0xFF92A58B);
  final Color cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- FUNGSI UPDATE NAMA KE SERVER GO ---
  Future<void> _updateNameInBackend(String newName) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isProcessing = true);
    
    try {
      final response = await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/update-name'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${userProvider.token}"
        },
        body: jsonEncode({"name": newName}),
      );

      if (response.statusCode == 200) {
        userProvider.updateName(newName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nama berhasil diperbarui"), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("Gagal memperbarui nama");
      }
    } catch (e) {
      debugPrint("Error update nama: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memperbarui nama ke server"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- FUNGSI PILIH GAMBAR DARI GALERI ---
  Future<void> _pickImage(UserProvider userProvider) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    
    if (pickedFile != null) {
      userProvider.updateImage(pickedFile.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil diperbarui secara lokal"), backgroundColor: Colors.green),
        );
      }
    }
  }

Future<void> _deleteAccountProcess(UserProvider userProvider) async {
    setState(() => _isProcessing = true);
    
    try {
      final response = await http.delete(
        Uri.parse('https://livera.mataramteachingfactory.store/api/user/delete'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${userProvider.token}"
        },
      );

      if (response.statusCode == 200) {
        // Memastikan penghapusan token di SharedPreferences selesai
        await userProvider.logout();
        
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Akun Anda telah berhasil dihapus secara permanen"), backgroundColor: Colors.green),
          );
          
          // Menggunakan pushNamedAndRemoveUntil atau mengarahkan ke rute paling awal
          // untuk merestart state navigasi secara total
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()), 
            (route) => false,
          );
        }
      } else {
        throw Exception("Server mengembalikan status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error hapus akun: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan otentikasi atau masalah koneksi"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // --- DIALOG KONFIRMASI HAPUS AKUN ---
  void _showDeleteConfirmationDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text("Hapus Akun?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Tindakan ini tidak dapat dibatalkan. Seluruh data perangkat purifikasi alga dan riwayat premium LIVERA Anda akan dihapus secara permanen.",
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccountProcess(userProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 24),
              _buildProfileHeader(userProvider),
              const SizedBox(height: 40),

              // --- BAGIAN AKSES ADMIN ---
              if (userProvider.email == "liverative@gmail.com") ...[
                _buildSectionHeader('ADMIN ACCESS'),
                _buildGroupedCard([
                  _buildListTile(
                    Icons.admin_panel_settings_rounded, 
                    'Device Generator', 
                    subtitle: 'Daftarkan SN massal ke PostgreSQL',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminToolScreen())),
                  ), 
                ]),
                const SizedBox(height: 32),
              ],

              // --- BAGIAN AKUN ---
              _buildSectionHeader('prof_section_account'.tr()),
              _buildGroupedCard([
                _buildListTile(
                  Icons.smartphone_outlined, 
                  'prof_dev_mgmt'.tr(), 
                  subtitle: 'prof_dev_subtitle'.tr(),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceManagementScreen(serialNumber: userProvider.serialNumber))),
                ),
                const Divider(height: 1, indent: 56),
                _buildListTile(
                  Icons.credit_card_outlined, 
                  'prof_subs'.tr(), 
                  subtitle: 'prof_subs_subtitle'.tr(),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPlanScreen())),
                ),
              ]),

              const SizedBox(height: 32),

              // --- BAGIAN PREFERENSI ---
              _buildSectionHeader('prof_section_pref'.tr()),
              _buildGroupedCard([
                _buildSwitchTile(
                  Icons.notifications_none_rounded, 
                  'prof_notif'.tr(), 
                  'prof_notif_subtitle'.tr(), 
                  _isNotificationOn, 
                  (val) => setState(() => _isNotificationOn = val),
                ),
              ]),

              const SizedBox(height: 48),
              
              // --- TOMBOL KELUAR AKUN ---
              _buildLogoutButton(userProvider),
              const SizedBox(height: 12),
              
              // --- TOMBOL HAPUS AKUN ---
              _buildDeleteAccountButton(userProvider),
              const SizedBox(height: 40),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF62B660))),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // UI COMPONENTS (HELPERS)
  // ==========================================

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('prof_title'.tr(), 
        style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfileHeader(UserProvider userProvider) {
    ImageProvider? profileImage;
    if (userProvider.imagePath != null) {
      if (userProvider.imagePath!.startsWith('http')) {
        profileImage = NetworkImage(userProvider.imagePath!);
      } else {
        profileImage = FileImage(File(userProvider.imagePath!));
      }
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: liveraGreen.withOpacity(0.2), width: 2)
              ),
              child: CircleAvatar(
                radius: 48, 
                backgroundColor: const Color(0xFFE8F5E9),
                backgroundImage: profileImage,
                child: profileImage == null ? Icon(Icons.person, size: 40, color: liveraGreen) : null,
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: () => _pickImage(userProvider),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: liveraGreen, 
                    shape: BoxShape.circle, 
                    border: Border.all(color: Colors.white, width: 2)
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 28),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                onSubmitted: (value) => _updateNameInBackend(value),
                style: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none, 
                  hintText: "Masukkan Nama", 
                  isDense: true
                ),
              ),
            ),
            Icon(Icons.edit_outlined, size: 18, color: textGrey.withOpacity(0.5)),
          ],
        ),
        Text(userProvider.email, style: TextStyle(color: textGrey, fontSize: 14)),
        const SizedBox(height: 16),
        _buildVipBadge(),
      ],
    );
  }

  Widget _buildVipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: liveraGreen, borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: liveraGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('prof_badge_vip'.tr(), 
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, 
        style: const TextStyle(
          color: Color(0xFF2D5A27), 
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.2
        )),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: liveraGreen.withOpacity(0.1), 
        child: Icon(icon, color: liveraGreen, size: 20)
      ),
      title: Text(title, 
        style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null 
        ? Text(subtitle, style: TextStyle(color: textGrey, fontSize: 12)) 
        : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String? subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: liveraGreen.withOpacity(0.1), 
        child: Icon(icon, color: liveraGreen, size: 20)
      ),
      title: Text(title, 
        style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null 
        ? Text(subtitle, style: TextStyle(color: textGrey, fontSize: 12)) 
        : null,
      trailing: Switch.adaptive(
        value: value, 
        onChanged: onChanged, 
        activeColor: liveraGreen
      ),
    );
  }

  Widget _buildLogoutButton(UserProvider userProvider) {
    return SizedBox(
      width: double.infinity, 
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          await userProvider.logout();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (_) => const LoginScreen()), 
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        label: Text('prof_logout'.tr(), 
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
          elevation: 0
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(UserProvider userProvider) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showDeleteConfirmationDialog(userProvider),
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
        label: const Text(
          "Hapus Akun Saya",
          style: TextStyle(
            color: Colors.redAccent, 
            fontSize: 14, 
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}