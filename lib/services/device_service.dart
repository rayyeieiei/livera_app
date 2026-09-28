import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';



class DeviceService {
  // Inisialisasi Ref ke folder "devices" di Singapore Region
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://livera-6a8d7-default-rtdb.asia-southeast1.firebasedatabase.app/"
  ).ref("devices");

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1. Verifikasi apakah SN ada di database
  Future<Map<String, dynamic>?> verifyDevice(String snFromQR) async {
    try {
      // Bersihin input dari spasi gaib dan paksa uppercase jir
      final cleanSN = snFromQR.trim().toUpperCase();
      final snapshot = await _dbRef.child(cleanSN).get();
      
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        return null; // SN Gak terdaftar di sistem
      }
    } catch (e) {
      print("🔥 Error Firebase Verify: $e");
      return null;
    }
  }

  /// 2. Klaim Perangkat atau Tambah Akses (Shared Access)
  Future<bool> claimDevice(String sn) async {
    try {
      final String? uid = _auth.currentUser?.uid;
      final String? email = _auth.currentUser?.email;
      
      if (uid == null) return false;

      final cleanSN = sn.trim().toUpperCase();
      
      // Ambil data terbaru dulu buat ngecek status
      final snapshot = await _dbRef.child(cleanSN).get();
      if (!snapshot.exists) return false;

      Map data = snapshot.value as Map;
      bool isAlreadyPaired = data['is_paired'] ?? false;

      // Update data di Firebase
      Map<String, dynamic> updates = {};

      if (!isAlreadyPaired) {
        // SKENARIO A: Alat masih baru (Jomblo)
        updates['is_paired'] = true;
        updates['owner_id'] = uid; // Jadi pemilik pertama jir
      }

      // SKENARIO B: Alat sudah taken, tapi user tau password (Shared Access)
      // Kita tambahkan UID user ini ke daftar orang yang boleh liat (Authorized)
      updates['authorized_users/$uid'] = {
        'email': email,
        'added_at': ServerValue.timestamp,
        'role': isAlreadyPaired ? 'guest' : 'owner',
      };

      await _dbRef.child(cleanSN).update(updates);
      return true;
    } catch (e) {
      print("🔥 Error Firebase Claim: $e");
      return false;
    }
  }

  /// 3. Ambil data alat secara real-time (Buat di Dashboard)
  Stream<DatabaseEvent> getDeviceStream(String sn) {
    return _dbRef.child(sn.trim().toUpperCase()).onValue;
  }

  /// 4. Hapus Perangkat (Unpair)
  Future<bool> unpairDevice(String sn) async {
    try {
      final String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final cleanSN = sn.trim().toUpperCase();

      // Hapus diri sendiri dari daftar authorized_users
      await _dbRef.child('$cleanSN/authorized_users/$uid').remove();
      
      return true;
    } catch (e) {
      return false;
    }
  }
}