import 'package:flutter/services.dart';

class LiveraSerialFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.toUpperCase();
    
    // 1. Kunci "LVRA-" di depan
    if (!text.startsWith("LVRA-")) {
      return oldValue; 
    }

    // 2. Logika Auto-Hyphen (LVRA-XX-XXX)
    // Karakter ke-8 (setelah XX tengah) harus otomatis '-'
    if (text.length > oldValue.text.length) {
      // Jika panjang mencapai 8 dan karakter ke-8 bukan '-', sisipkan '-'
      if (text.length == 8 && text[7] != '-') {
        text = "${text.substring(0, 7)}-${text.substring(7)}";
      }
    }

    // 3. Batasi Panjang Maksimal (LVRA-XX-XXX = 11 Karakter)
    if (text.length > 11) {
      return oldValue;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}