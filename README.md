# LIVERA App 🌱

> **Revolutionary Bio-tech Wellness & Intelligent Microalgae Bioreactor Management**

Aplikasi mobile dan web berbasis Flutter untuk memantau, mengontrol, dan menganalisis ekosistem bioreaktor mikroalga (*Chlorella vulgaris*). LIVERA membantu pengguna mengonversi karbon dioksida (CO₂) di dalam ruangan menjadi oksigen (O₂) segar serta memproduksi biomassa bernutrisi tinggi secara mandiri.

---

## 📋 Fitur Utama

- 🌬️ **Real-Time Telemetry Dashboard**: Pemantauan langsung kadar gas CO₂, suhu air, keasaman (pH), intensitas cahaya (lux), dissolved O₂, dan laju aliran udara (airflow).
- 🚨 **Smart Alerts & Emergency Notifications**: Notifikasi lokal otomatis saat kondisi parameter reaktor kritis (misal CO₂ overload atau pH asam).
- ⚙️ **Kontrol Aktuator Cerdas**:
  - Pompa Aerasi & Blower Kipas dengan animasi *smooth ramp engine*.
  - Sistem Pencahayaan LED Grow Light.
  - Modul Dosis & Injeksi Nutrisi (N-P-K).
  - Pengendali Humidifier & Kelembapan Ruangan.
  - Profil Manajemen Daya (Eco, Normal, Turbo).
- 🌾 **Pemanenan & Pengolahan Biomassa**:
  - Estimasi kesiapan panen reaktor 5L dengan target 3.5 g/L.
  - Panduan interaktif 4-langkah pembuatan Pupuk Organik Cair.
  - Panduan interaktif 4-langkah pemrosesan Suplemen Kesehatan (*Chlorella*).
- 📊 **Analitik & Ekspor Laporan PDF**: Visualisasi tren data sensor, kalkulasi skor kesehatan udara (*Air Health Score*), dan ekspor laporan resmi dalam format PDF yang siap cetak.
- 📱 **Otentikasi & Multi-Pengguna**:
  - Login email & Google Sign-In terintegrasi backend Gin & PostgreSQL.
  - Verifikasi OTP email 6-digit & registrasi profil.
  - Pairing alat via pemindaian kamera QR / impor galeri / input manual dengan auto-formatter nomor seri.
  - Fitur berbagi kontrol alat dengan anggota keluarga / tim (*Shared Device Access*).
- 🌐 **Dukungan Multi-Bahasa**: Bahasa Indonesia & English (US) dengan *EasyLocalization*.
- 👑 **Membership VIP**: Fitur *Advanced Data Sheet* untuk peneliti dan pengguna tingkat lanjut.
- 🛠️ **Admin Tools**: Pendaftaran serial number dan pembuatan kode QR alat secara massal.

Untuk daftar fungsi dan status implementasi teknis lengkap, silakan baca [docs/FEATURE_MAP.md](docs/FEATURE_MAP.md).

---

## 🛠️ Tech Stack & Dependensi

| Layer | Teknologi |
|---|---|
| **Frontend Framework** | [Flutter](https://flutter.dev/) (>= 3.0.0, Dart >= 3.0.0) |
| **State Management** | [Provider](https://pub.dev/packages/provider) v6.1.2 |
| **Persistent Storage** | [shared_preferences](https://pub.dev/packages/shared_preferences) v2.5.5 |
| **Internationalization** | [easy_localization](https://pub.dev/packages/easy_localization) v3.0.7 |
| **Scanner & Camera** | [mobile_scanner](https://pub.dev/packages/mobile_scanner) v3.0.0, [image_picker](https://pub.dev/packages/image_picker) |
| **Reporting & PDF** | [pdf](https://pub.dev/packages/pdf), [printing](https://pub.dev/packages/printing), [screenshot](https://pub.dev/packages/screenshot) |
| **Notifications** | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) v17.0.0 |
| **Cloud & Backend** | [Golang Gin](https://gin-gonic.com/) REST API + PostgreSQL, [Firebase Core / Auth / RTDB](https://firebase.google.com/) |
| **IoT & Hardware** | ESP32 Microcontroller, Blynk Cloud IoT, LiquidCrystal I2C, Wokwi Simulator |

---

## 🚀 Memulai (Getting Started)

### Prasyarat:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) versi 3.10.x atau lebih baru.
- [Dart SDK](https://dart.dev/get-dart) versi 3.x.
- Android Studio / VS Code dengan ekstensi Flutter & Dart.

### Instalasi:

1. **Clone repository:**
   ```bash
   git clone https://github.com/rayyeieiei/livera_app.git
   cd livera_app
   ```

2. **Pasang dependensi Flutter:**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Lingkungan:**
   Salin file `.env.example` sebagai referensi konfigurasi:
   ```bash
   cp .env.example .env
   ```

4. **Verifikasi kode & analisis static:**
   ```bash
   dart analyze lib
   ```

5. **Jalankan aplikasi:**
   - Di Android / Emulator:
     ```bash
     flutter run
     ```
   - Di Web (Chrome):
     ```bash
     flutter run -d chrome
     ```
   - Di Desktop Windows:
     ```bash
     flutter run -d windows
     ```

---

## 📁 Struktur Direktori Proyek

```text
livera_app/
├── android/                  # Konfigurasi platform Android & gradle
├── assets/                   # Aset visual & translasi bahasa
│   ├── icons/                # Ikon SVG/PNG aplikasi
│   ├── images/               # Ilustrasi edukasi & onboarding (WebP/PNG)
│   └── translations/         # File translasi (en.json, id.json)
├── docs/                     # Dokumentasi teknis & arsitektur
│   └── FEATURE_MAP.md        # Peta fitur dan inventaris modul lengkap
├── ios/                      # Konfigurasi platform iOS
├── lib/
│   ├── core/                 # Tema, warna, dan konstanta aplikasi
│   ├── livera_hardware/      # Skrip firmware ESP32 & simulasi Wokwi
│   ├── models/               # Model data (SensorData, DeviceModel)
│   ├── services/             # Service API, notifikasi, admin, kalkulasi alga
│   ├── ui/screens/           # Seluruh layar antarmuka aplikasi
│   ├── firebase_options.dart # Konfigurasi FlutterFire multi-platform
│   └── main.dart             # Titik masuk utama aplikasi (Entry Point)
├── test/                     # Widget & unit testing
├── web/                      # Konfigurasi platform Flutter Web
└── pubspec.yaml              # Manifest dependensi proyek
```

---

## 📄 Lisensi & Kontribusi

Proyek ini dikembangkan untuk ekosistem LIVERA. Hak cipta dilindungi undang-undang.
