import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';


class UserProvider extends ChangeNotifier {
  String _name = "Budi";
  String? _imagePath; // Nyimpen alamat foto di memori HP

  String get name => _name;
  String? get imagePath => _imagePath;

  // Fungsi buat update nama
  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  // Fungsi buat update foto
  void updateImage(String path) {
    _imagePath = path;
    notifyListeners(); // Semua layar yang dengerin bakal berubah!
  }
}