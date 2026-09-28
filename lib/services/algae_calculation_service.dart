class AlgaeCalculationService {
  // Fungsi static biar bisa dipanggil tanpa perlu inisialisasi class
  static double getGrowthEfficiency({
    required double temp,
    required double ph,
    required int co2,
    required int light,
  }) {
    double score = 0;

    // Logika Suhu
    if (temp >= 25 && temp <= 30) score += 25;
    else if (temp > 20 && temp < 35) score += 15;
    else score += 5;

    // Logika pH
    if (ph >= 8.0 && ph <= 9.0) score += 25;
    else if (ph >= 7.0 && ph <= 10.0) score += 15;
    else score += 5;

    // Logika CO2
    if (co2 >= 1000 && co2 <= 1500) score += 25;
    else if (co2 > 400 && co2 < 2000) score += 15;
    else score += 5;

    // Logika Cahaya
    if (light > 700) score += 25;
    else if (light > 400) score += 15;
    else score += 5;

    return score;
  }
}