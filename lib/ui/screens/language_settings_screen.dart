import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late String _selectedLang; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambil bahasa yang aktif sekarang dari Easy Localization
    _selectedLang = context.locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
                color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'set_language'.tr(), 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87, 
            fontSize: 18, 
            fontWeight: FontWeight.w600
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildLanguageCard(
                  id: 'en',
                  title: 'English (US)',
                  flagPath: 'assets/icons/flag_us.png',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildLanguageCard(
                  id: 'id',
                  title: 'Bahasa Indonesia',
                  flagPath: 'assets/icons/flag_id.png',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await context.setLocale(Locale(_selectedLang));

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_selectedLang == 'id' 
                            ? "Bahasa diperbarui!" 
                            : "Language Updated!"),
                        duration: const Duration(seconds: 1),
                        backgroundColor: const Color(0xFF39FF14).withOpacity(0.8),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Changes', 
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER: KARTU BAHASA ---
  Widget _buildLanguageCard({
    required String id, 
    required String title, 
    required String flagPath, 
    required bool isDark
  }) {
    bool isSelected = _selectedLang == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLang = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF39FF14) 
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(flagPath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w500, 
                  color: isDark ? Colors.white : Colors.black87
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF39FF14) : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF39FF14) : Colors.transparent,
              ),
              child: isSelected 
                ? const Icon(Icons.check, size: 16, color: Colors.black) 
                : null,
            ),
          ],
        ),
      ),
    );
  }
}