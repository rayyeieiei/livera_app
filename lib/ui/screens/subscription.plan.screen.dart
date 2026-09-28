import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; // Buat UserProvider

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  bool _isLoading = false;

  // --- LOGIKA: PROSES SUBSCRIBE BOHONGAN TAPI REAL ---
  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final response = await http.post(
        Uri.parse('https://livera.mataramteachingfactory.store/api/user/subscribe'),
        headers: {
          "Authorization": "Bearer ${userProvider.token}"
        },
      );

      if (response.statusCode == 200) {
        userProvider.setPremium(true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("GACOR! Pembayaran berhasil, akun kamu sekarang Premium!"), 
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Langsung tendang balik ke halaman Profile setelah sukses
          Navigator.pop(context); 
        }
      } else {
        throw Exception("Gagal server saat subscribe: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error subscribe: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sistem lagi sibuk, coba lagi nanti!"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF0B2A12);
    final isPremium = Provider.of<UserProvider>(context).isPremium;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'vip_title'.tr(), 
          style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildPremiumCard(),
                const SizedBox(height: 32),
                Text(
                  'vip_benefits_header'.tr(), 
                  style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                _buildBenefitItem(Icons.analytics_outlined, 'vip_benefit1_title'.tr(), 'vip_benefit1_desc'.tr(), textColor),
                _buildBenefitItem(Icons.school_outlined, 'vip_benefit2_title'.tr(), 'vip_benefit2_desc'.tr(), textColor),
                _buildBenefitItem(Icons.devices_rounded, 'vip_benefit3_title'.tr(), 'vip_benefit3_desc'.tr(), textColor), // Ikon banyak HP/Device
                _buildBenefitItem(Icons.group_add_outlined, 'vip_benefit4_title'.tr(), 'vip_benefit4_desc'.tr(), textColor), // Ikon nambah banyak orang
              ],
            ),
          ),
        _buildBottomAction(isPremium),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E9121), Color(0xFF719F6F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF2D5A27).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'vip_premium_label'.tr(), 
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)
            ),
          ),
          const SizedBox(height: 20),
          Text('vip_price'.tr(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
          Text('vip_per_month'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String desc, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF2D5A27).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF2D5A27), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Color(0xFF7B8B7A), fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF7),
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: (isPremium || _isLoading) ? null : _handleSubscribe, 
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremium ? Colors.grey.shade300 : const Color(0xFF2D5A27),
              disabledBackgroundColor: Colors.grey.shade300, 
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              elevation: isPremium ? 0 : 4,
              shadowColor: isPremium ? Colors.transparent : const Color(0xFF2D5A27).withOpacity(0.3),
            ),
            child: _isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  isPremium ? "Sudah berlangganan" : 'vip_btn_subscribe'.tr(), 
                  style: TextStyle(
                    color: isPremium ? Colors.grey.shade600 : Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'vip_footer'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7B8B7A), fontSize: 10, height: 1.5),
          ),
        ],
      ),
    );
  }
}