import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// --- 1. MODEL DATA ---
class HistoryItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final String category;

  HistoryItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    required this.category,
  });
}

class HistoryUtama extends StatefulWidget {
  const HistoryUtama({super.key});

  @override
  State<HistoryUtama> createState() => _HistoryUtamaState();
}

class _HistoryUtamaState extends State<HistoryUtama> {
  String _selectedCategoryKey = 'hist_filter_all';

  final List<HistoryItem> _allLogs = [
    // --- Data Baru (Hari Ini) ---
    HistoryItem(
      title: 'hist_log_harvest_success_title'.tr(),
      subtitle: 'hist_log_harvest_success_desc'.tr(args: ['340g']),
      time: 'hist_time_hours'.tr(args: ['2']),
      icon: Icons.eco_rounded,
      color: const Color(0xFF26A69A),
      category: 'hist_filter_harvest',
    ),
    HistoryItem(
      title: 'hist_log_nutrients_added_title'.tr(),
      subtitle: 'hist_log_nutrients_added_desc'.tr(args: ['NPK', 'Tank A']),
      time: 'hist_time_hours'.tr(args: ['5']),
      icon: Icons.science_rounded,
      color: const Color(0xFF4CAF50),
      category: 'hist_filter_nutrients',
    ),
    HistoryItem(
      title: 'hist_log_ph_adjusted_title'.tr(),
      subtitle: 'hist_log_ph_adjusted_desc'.tr(args: ['7.2']),
      time: 'hist_time_hours'.tr(args: ['8']),
      icon: Icons.opacity_rounded,
      color: const Color(0xFF42A5F5),
      category: 'hist_filter_ph',
    ),

    // --- Data Minggu Lalu (Efek Pengguna Lama) ---
    HistoryItem(
      title: 'hist_log_light_cycle_title'.tr(),
      subtitle: 'hist_log_light_cycle_desc'.tr(args: ['16h']),
      time: 'hist_time_weeks'.tr(args: ['1']),
      icon: Icons.light_mode_rounded,
      color: const Color(0xFFF06292),
      category: 'hist_filter_light',
    ),
    HistoryItem(
      title: 'hist_log_iron_added_title'.tr(),
      subtitle: 'hist_log_iron_added_desc'.tr(args: ['50ml']),
      time: 'hist_time_weeks'.tr(args: ['2']),
      icon: Icons.science_rounded,
      color: const Color(0xFF4CAF50),
      category: 'hist_filter_nutrients',
    ),

    // --- Data Bulan Lalu (The Real Sesepuh) ---
    HistoryItem(
      title: 'hist_log_calibration_title'.tr(),
      subtitle: 'hist_log_calibration_desc'.tr(),
      time: 'hist_time_months'.tr(args: ['1']),
      icon: Icons.settings_input_component_rounded,
      color: const Color(0xFF795548),
      category: 'hist_filter_all', // Masuk kategori general
    ),
    HistoryItem(
      title: 'hist_log_first_harvest_title'.tr(),
      subtitle: 'hist_log_first_harvest_desc'.tr(),
      time: 'hist_time_months'.tr(args: ['2']),
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFFFFB300),
      category: 'hist_filter_harvest',
    ),
    HistoryItem(
      title: 'hist_log_joined_title'.tr(),
      subtitle: 'hist_log_joined_desc'.tr(),
      time: 'hist_time_months'.tr(args: ['3']),
      icon: Icons.verified_user_rounded,
      color: const Color(0xFF62B660),
      category: 'hist_filter_all',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<HistoryItem> displayLogs = _allLogs.where((log) {
      if (_selectedCategoryKey == 'hist_filter_all') return true;
      return log.category == _selectedCategoryKey;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            _buildCategoryBar(isDark),
            
            Expanded(
              child: displayLogs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayLogs.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(displayLogs[index], isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Text(
        'hist_title'.tr(),
        style: TextStyle(
          fontSize: 28, 
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white : const Color(0xFF0F1720)
        ),
      ),
    );
  }

  Widget _buildCategoryBar(bool isDark) {
    final categoryKeys = [
      'hist_filter_all', 
      'hist_filter_nutrients', 
      'hist_filter_harvest', 
      'hist_filter_ph', 
      'hist_filter_light'
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryKeys.length,
        itemBuilder: (context, index) {
          final key = categoryKeys[index];
          bool isSelected = _selectedCategoryKey == key;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: ChoiceChip(
              label: Text(key.tr()), // Tampilan translate, ID tetep key
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedCategoryKey = key);
              },
              selectedColor: const Color(0xFF1B5E3F),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E1E1E)),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: item.color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(item.subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ],
            ),
          ),
          Text(item.time, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No activity in this category", style: TextStyle(color: Colors.grey)).tr(),
        ],
      ),
    );
  }
}