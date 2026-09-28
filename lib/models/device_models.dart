class DeviceModel {
  final int id;
  final String serialNumber;
  final String deviceName;
  final int userId;
  final String pin;
  final bool isPaired;
  final DateTime createdAt;

  DeviceModel({
    required this.id,
    required this.serialNumber,
    required this.deviceName,
    required this.userId,
    required this.pin,
    required this.isPaired,
    required this.createdAt,
  });

  // Fungsi buat ngerubah JSON dari Postman tadi jadi Object Dart
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['ID'] ?? 0,
      serialNumber: json['serial_number'] ?? '',
      deviceName: json['device_name'] ?? 'Alat Tanpa Nama',
      userId: json['user_id'] ?? 0,
      pin: json['pin'] ?? '',
      isPaired: json['is_paired'] ?? false,
      createdAt: DateTime.parse(json['CreatedAt']),
    );
  }
}