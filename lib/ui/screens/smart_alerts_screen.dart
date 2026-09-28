import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SmartAlertsScreen extends StatefulWidget {
  const SmartAlertsScreen({super.key});

  @override
  State<SmartAlertsScreen> createState() => _SmartAlertsScreenState();
}

class _SmartAlertsScreenState extends State<SmartAlertsScreen> {
  bool _isCo2Enabled = true;
  double _co2Threshold = 1000.0;

  bool _isPm25Enabled = true;
  double _pm25Threshold = 50.0;

  bool _isAlgaeEnabled = true;

  // --- PALETTE WARNA ---
  final Color brandOrange = const Color(0xFFFF5722);
  final Color brandGreen = const Color(0xFF39FF14);
  final Color textDark = const Color(0xFF102027);
  final Color textGrey = const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF6F7F8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text('alert_header'.tr(), 
          style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 20),
          // 1. HERO SECTION (Bell Icon)
          _buildHeroSection(),
          const SizedBox(height: 32),

          // 2. CO2 THRESHOLD CARD
          _buildThresholdCard(
            title: "alert_co2_title".tr(),
            icon: Icons.air_rounded,
            description: "alert_co2_msg".tr(),
            value: "${_co2Threshold.toInt()} ppm",
            min: 400,
            max: 2000,
            currentValue: _co2Threshold,
            isEnabled: _isCo2Enabled,
            onSwitch: (val) => setState(() => _isCo2Enabled = val),
            onSlider: (val) => setState(() => _co2Threshold = val),
          ),

          // 3. PM2.5 THRESHOLD CARD
          _buildThresholdCard(
            title: "alert_pm25_title".tr(),
            icon: Icons.wb_cloudy_outlined,
            description: "alert_pm25_msg".tr(),
            value: "${_pm25Threshold.toInt()} µg/m³",
            min: 0,
            max: 150,
            currentValue: _pm25Threshold,
            isEnabled: _isPm25Enabled,
            onSwitch: (val) => setState(() => _isPm25Enabled = val),
            onSlider: (val) => setState(() => _pm25Threshold = val),
          ),

          // 4. ALGAE NUTRITION CARD
          _buildAlgaeCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- HELPER: HERO SECTION ---
  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: brandOrange.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Icon(Icons.notifications_active_outlined, color: brandOrange, size: 40),
        ),
        const SizedBox(height: 24),
        Text('alert_title'.tr(), style: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'alert_desc'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(color: textGrey, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  // --- HELPER: THRESHOLD CARD (REUSABLE) ---
  Widget _buildThresholdCard({
    required String title, required IconData icon, required String description,
    required String value, required double min, required double max,
    required double currentValue, required bool isEnabled,
    required Function(bool) onSwitch, required Function(double) onSlider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: brandOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              Switch(value: isEnabled, onChanged: onSwitch, activeColor: brandOrange),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(style: TextStyle(color: textGrey, fontSize: 14), children: [
              TextSpan(text: description),
              TextSpan(text: value, style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: brandOrange,
              inactiveTrackColor: const Color(0xFFF0F4F1),
              thumbColor: Colors.white,
              overlayColor: brandOrange.withOpacity(0.1),
            ),
            child: Slider(min: min, max: max, value: currentValue, onChanged: isEnabled ? onSlider : null),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${min.toInt()} ${title.contains('CO') ? 'ppm' : 'µg/m³'}", style: TextStyle(color: textGrey, fontSize: 12)),
              Text("${max.toInt()} ${title.contains('CO') ? 'ppm' : 'µg/m³'}", style: TextStyle(color: textGrey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  // --- HELPER: ALGAE NUTRITION CARD ---
  Widget _buildAlgaeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.biotech_outlined, color: Colors.green.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text('alert_nutrition_title'.tr(), style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              Switch(value: _isAlgaeEnabled, onChanged: (v) => setState(() => _isAlgaeEnabled = v), activeColor: Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "alert_nutrition_desc".tr(),
            style: TextStyle(color: textGrey, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0F4F1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('alert_freq_label'.tr(), style: TextStyle(color: textGrey, fontSize: 12)),
                  Text('alert_freq_value'.tr(), style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text('alert_next_date'.tr(args: [DateTime.now().add(Duration(days: 7)).toLocal().toString().split(' ')[0]]), style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}