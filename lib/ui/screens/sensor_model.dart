class SensorData {
  final double ph;
  final double temperature;
  final double co2;          // Baru
  final double airflow;     // Baru
  final double biomass;     // Baru
  final double light;       // Baru
  final bool isOnline;

  SensorData({
    required this.ph, 
    required this.temperature, 
    required this.co2, 
    required this.airflow, 
    required this.biomass, 
    required this.light, 
    required this.isOnline
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      ph: (json['ph'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      co2: (json['co2'] ?? 0.0).toDouble(),
      airflow: (json['airflow'] ?? 0.0).toDouble(),
      biomass: (json['biomass'] ?? 0.0).toDouble(),
      light: (json['light'] ?? 0.0).toDouble(),
      isOnline: json['is_online'] ?? false,
    );
  }
}