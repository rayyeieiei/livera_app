import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livera_app/ui/screens/splash_screen.dart'; // 🔥 KUNCI: Import Splash Screen lu!
import 'package:livera_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await NotificationService.init(); 
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('id')],
      path: 'assets/translations', 
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const LiveraApp(),
      ),
    ),
  );
}

// ==========================================
// --- USER PROVIDER (Jantung Data User) ---
// ==========================================
class UserProvider extends ChangeNotifier {
  String _name = "User Livera"; 
  String _email = "guest@livera.com"; 
  String? _imagePath;
  String _serialNumber = ""; 
  String? _token;

  String get name => _name;
  String get email => _email; 
  String? get imagePath => _imagePath;
  String get serialNumber => _serialNumber;
  String? get token => _token;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }

  void setInitialSerialNumber(String sn) {
    _serialNumber = sn;
    notifyListeners();
  }

  void setPremium(bool status) async {
    _isPremium = status;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', status);
  }

  // --- UPDATE & PERSISTENCE LOGIC ---

  void updateSerialNumber(String sn) async {
    _serialNumber = sn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_serial', sn);
  }

  void updateName(String newName) async {
    _name = newName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_name', newName);
  }

  void updateImage(String? newPath) async {
    _imagePath = newPath;
    notifyListeners();
    if (newPath != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_image', newPath);
    }
  }

  void updateEmail(String newEmail) async {
    _email = newEmail;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', newEmail);
  }

  void setUserData(String name, String email, {String? imagePath}) async {
    _name = name;
    _email = email;
    if (imagePath != null) _imagePath = imagePath;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_name', name);
    await prefs.setString('saved_email', email);
    if (imagePath != null) await prefs.setString('saved_image', imagePath);
  }

  void loadSavedData(SharedPreferences prefs) {
    // 🔥 UDAH NORMAL: Balik ke default kalau belum login
    _name = prefs.getString('saved_name') ?? "User Livera"; 
    _email = prefs.getString('saved_email') ?? "guest@livera.com";
    _imagePath = prefs.getString('saved_image');
    _serialNumber = prefs.getString('saved_serial') ?? ""; 
    _token = prefs.getString('jwt_token');
    _isPremium = prefs.getBool('is_premium') ?? false; 
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('saved_serial');
    await prefs.remove('saved_name');
    await prefs.remove('saved_email');
    await prefs.remove('saved_image');
    await prefs.remove('is_premium');
    
    _token = null;
    _serialNumber = "";
    _name = "User Livera";
    _email = "guest@livera.com";
    _imagePath = null;
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode get themeMode => ThemeMode.light; 
}

// ==========================================
// --- LIVERA APP ---
// ==========================================
class LiveraApp extends StatelessWidget {
  const LiveraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Livera App',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale, 
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF62B660)),
      ),
      // 🔥 SMART ROUTING: Langsung panggil SplashScreen, dia yang ngurusin jalan ceritanya!
      home: const SplashScreen(),
    );
  }
}