import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class FAQItem {
  final String questionKey;
  final String answerKey;

  FAQItem({required this.questionKey, required this.answerKey});
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<FAQItem> _allFaqs = [
    FAQItem(questionKey: 'help_faq_1', answerKey: 'help_ans_1'),
    FAQItem(questionKey: 'help_faq_2', answerKey: 'help_ans_2'),
    FAQItem(questionKey: 'help_faq_3', answerKey: 'help_ans_3'),
    FAQItem(questionKey: 'help_faq_4', answerKey: 'help_ans_4'),
    FAQItem(questionKey: 'help_faq_policy', answerKey: 'help_ans_policy'),
    FAQItem(questionKey: 'help_faq_billing', answerKey: 'help_ans_billing'),
  ];

  List<FAQItem> _filteredFaqs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _filteredFaqs = _allFaqs;
    super.initState();
  }

  // --- 3. LOGIC PENCARIAN (FILTER BERDASARKAN HASIL TRANSLASI) ---
  void _runFilter(String enteredKeyword) {
    List<FAQItem> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allFaqs;
    } else {
      results = _allFaqs.where((faq) {
        final translatedQuestion = faq.questionKey.tr().toLowerCase();
        return translatedQuestion.contains(enteredKeyword.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredFaqs = results;
    });
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'liverative@gmail.com',
      query: 'subject=LIVERA Support Request',
    );
    if (!await launchUrl(emailUri)) {
      debugPrint("Gagal buka Gmail");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'help_title'.tr(), 
          style: TextStyle(color: primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildSearchBox(isDark),
          const SizedBox(height: 24),

          Text(
            'help_faq_header'.tr(), 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)
          ),
          const SizedBox(height: 12),

          // LIST FAQ
          if (_filteredFaqs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text('help_empty_state'.tr(), style: const TextStyle(color: Colors.grey))
              ),
            )
          else
            ..._filteredFaqs.map((faq) => _buildFAQTile(faq, primaryTextColor)).toList(),

          const SizedBox(height: 32),

          // SECTION CONTACT
          Text(
            'help_contact_header'.tr(), 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)
          ),
          const SizedBox(height: 16),
          
          _buildSupportCard(
            'help_chat_title'.tr(), 
            'help_chat_subtitle'.tr(args: ['5']), 
            Icons.chat_bubble_outline, 
            const Color(0xFFE6F4EA), 
            Colors.green, 
            () {}
          ),
          _buildSupportCard(
            'help_email_title'.tr(), 
            'help_email_subtitle'.tr(args: ['24']), 
            Icons.email_outlined, 
            const Color(0xFFE8F0FE), 
            Colors.blue, 
            _launchEmail
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F5F7), 
        borderRadius: BorderRadius.circular(12)
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        onChanged: (value) => _runFilter(value),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8A8F)),
          hintText: "help_search_hint".tr(),
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFAQTile(FAQItem faq, Color textColor) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: Colors.green,
        title: Text(
          faq.questionKey.tr(), 
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 4),
            child: Text(
              faq.answerKey.tr(), 
              style: const TextStyle(color: Colors.grey, height: 1.4)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(String t, String s, IconData i, Color bg, Color iconCol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle), 
              child: Icon(i, color: iconCol, size: 24)
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(s, style: const TextStyle(color: Color(0xFF8A8A8F), fontSize: 13)),
                ]
              )
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}