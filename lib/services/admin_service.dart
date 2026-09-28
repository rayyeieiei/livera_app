import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDeviceService {
  // Pastiin URL-nya tetep ke Singapore jir
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://livera-6a8d7-default-rtdb.asia-southeast1.firebasedatabase.app/"
  ).ref("devices");

  // --- 1. FUNGSI GENERATE PASSWORD ACAK ---
  String _generateRandomPassword(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Gak pake O dan 0 biar gak ketuker jir
    return List.generate(length, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // --- 2. FUNGSI BULK REGISTER (DAFTARIN MASSAL) ---
  Future<void> bulkRegisterDevices(int startNumber, int count) async {
    print("🚀 Memulai proses pendaftaran $count alat...");

    Map<String, dynamic> bulkData = {};

    for (int i = 0; i < count; i++) {
      // Format SN: LVRA-X1-001, LVRA-X1-002, dst.
      int currentId = startNumber + i;
      String sn = "LVRA-X1-${currentId.toString().padLeft(3, '0')}";
      
      // Bikin password acak 6 digit buat tiap alat
      String pass = _generateRandomPassword(6);

      bulkData[sn] = {
        "password": pass,
        "is_paired": false,
        "owner_id": "",
        "created_at": ServerValue.timestamp,
        "status": "ready",
      };

      print("✅ Generated: $sn | Password: $pass");
    }

    try {
      // Tembak sekaligus ke Firebase pake update() biar kenceng jir
      await _dbRef.update(bulkData);
      print("🎯 MANTAP! $count alat berhasil terdaftar di database.");
    } catch (e) {
      print("❌ Gagal bulk register: $e");
    }
  }
}