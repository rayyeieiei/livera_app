class SensorData {
  final double temperature;
  final double ph;
  final double co2;
  final double airflow;
  final double biomass;
  final double light;
  final bool isOnline;

  SensorData({
    required this.temperature,
    required this.ph,
    required this.co2,
    required this.airflow,
    required this.biomass,
    required this.light,
    required this.isOnline,
  });

factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 0).toDouble(),
      ph: (json['ph'] ?? 0).toDouble(),
      // 🔥 Cek 3 baris ini jir! Jangan sampe tulisannya json['CO2'] atau json['air_flow']
      co2: (json['co2'] ?? 0).toDouble(),
      airflow: (json['airflow'] ?? 0).toDouble(),
      light: (json['light'] ?? 0).toDouble(),
      
      biomass: (json['biomass'] ?? 0).toDouble(),
      isOnline: json['is_online'] ?? false,
    );
  }
}