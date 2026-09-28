import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; 
import 'device_setup_screen.dart';
import 'help_center_screen.dart';
import 'language_settings_screen.dart';
import 'smart_alerts_screen.dart';
import 'profile_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔥 Tambahin package ini di pubspec.yaml buat buka link toko

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color textDark = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color bgGrey = Color(0xFFF9FAFB);

  // 🔥 Fungsi pembantu buat buka link marketplace / toko nutrisi alga
  Future<void> _launchStoreUrl() async {
    final Uri url = Uri.parse('https://tokopedia.com/livera-algae-store'); // 🛒 Ganti pake link toko lu nanti bray
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 10),
                  
                  // PROFILE CARD
                  _buildProfileCard(context, userProvider, isDark), 
                  
                  const SizedBox(height: 24),
                  _buildNewUserStats(isDark),
                  const SizedBox(height: 32),

                  // 🔥 MENU BARU: Beli Nutrisi Alga (Ditaruh paling atas biar gampang di-akses)
                  _buildMenuItem(
                    context,
                    icon: Icons.shopping_bag_outlined, 
                    title: "Buy Algae Nutrition", 
                    subtitle: "Order Chlorella nutrient refills & materials", 
                    iconBg: const Color(0xFFECFDF5), // Hijau mint segar
                    iconColor: const Color(0xFF059669), // Hijau alga sukses
                    isDark: isDark,
                    onTap: () => _launchStoreUrl(),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_active_outlined, 
                    title: "alert_header".tr(), 
                    subtitle: "Manage safety limits & push notifications", 
                    iconBg: const Color(0xFFFFF7ED), 
                    iconColor: const Color(0xFFEA580C),
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartAlertsScreen())),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.wifi_rounded, 
                    title: 'set_deviceSetup'.tr(), 
                    subtitle: "WiFi Pairing & Calibration", 
                    iconBg: const Color(0xFFEFF6FF), 
                    iconColor: const Color(0xFF2563EB),
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DeviceSetupScreen())),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'set_helpCenter'.tr(), 
                    subtitle: "FAQs & Support",
                    iconBg: const Color(0xFFF9FAFB),
                    iconColor: const Color(0xFF4B5563),
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen())),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.translate_rounded, 
                    title: 'set_language'.tr(), 
                    subtitle: "Choose your preferred language", 
                    iconBg: const Color(0xFFF0FDF4), 
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen())),
                  ),

                  const SizedBox(height: 40),
                  _buildLogoutButton(context, userProvider, 'set_logout'.tr()), 
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('Firmware Version: V2.0.4', style: TextStyle(color: textGrey, fontSize: 12)),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('set_title'.tr(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : textDark)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _showNotificationSheet(context); 
            },
            child: Stack(
              children: [
                Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : textDark, size: 28),
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

  Widget _buildProfileCard(BuildContext context, UserProvider user, bool isDark) {
    ImageProvider? profileImage;
    if (user.imagePath != null && user.imagePath!.isNotEmpty) {
      if (user.imagePath!.startsWith('http')) {
        profileImage = NetworkImage(user.imagePath!);
      } else {
        profileImage = FileImage(File(user.imagePath!));
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : textDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF62B660),
              backgroundImage: profileImage,
              child: profileImage == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email, 
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNewUserStats(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : bgGrey, 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatRow(Ionicons.calendar_clear_outline, 'Joined since 2026', isDark),
          _buildStatRow(Ionicons.leaf_outline, 'Harvested: 5.2kg', isDark, isBold: true),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String text, bool isDark, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, color: textGrey, size: 18),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: isDark ? Colors.white70 : textGrey, fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color iconBg, required Color iconColor, required bool isDark, VoidCallback? onTap, bool isComingSoon = false}) {
    return GestureDetector(
      onTap: isComingSoon ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : textDark)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : textGrey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, UserProvider user, String label) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () async {
          await user.logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
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
}