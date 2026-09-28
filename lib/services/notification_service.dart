import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Inisialisasi awal pas aplikasi pertama kali dibuka
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/livera_gacor'); // 👈 Pake logo alga ijo lu yang baru jir!

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Kalo user nge-klik notifikasinya, mau dibawa ke halaman mana bisa diatur di sini jir
      },
    );

    // Minta izin langsung ke user Samsung lu
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 2. FUNGSI PEMANGGIL NOTIFIKASI DARURAT LIVERA
  static Future<void> showEmergencyNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'livera_emergency_channel', // ID Channel
      'LIVERA Emergency Alerts', // Nama Channel
      channelDescription: 'Notifikasi darurat terkait kondisi perangkat LIVERA',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      // Lu bisa custom suara atau lampu LED di sini kalau mau jir
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }
}