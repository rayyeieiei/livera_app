import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  
  File? _imageFile;
  int _currentStep = 0;
  bool _isSaving = false;

  // --- FUNGSI AMBIL FOTO ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // --- FUNGSI UPLOAD DATA KE GO BACKEND ---
  Future<void> _finishSetup() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String token = userProvider.token ?? "";
    
    setState(() => _isSaving = true);

    try {
      if (_nameController.text.isNotEmpty) {
        await http.post(
          Uri.parse('https://livera.mataramteachingfactory.store/api/update-name'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"name": _nameController.text.trim()}),
        );
        userProvider.updateName(_nameController.text.trim());
      }

      // 2. UPLOAD FOTO PROFIL (MULTIPART)
      if (_imageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://livera.mataramteachingfactory.store/api/update-photo'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(await http.MultipartFile.fromPath('photo', _imageFile!.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var data = jsonDecode(responseData);
          userProvider.updateImage(data['url']); // Simpan URL dari server ke provider
        }
      }

      if (mounted) {
        // 3. TENDANG KE DASHBOARD
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(serialNumber: userProvider.serialNumber)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Gagal setup profil: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishSetup, 
            child: const Text("Lewati", style: TextStyle(color: Colors.grey))
          )
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5A27)))
        : Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepName(),
                    _buildStepPhoto(),
                  ],
                ),
              ),
              _buildBottomButton(),
              const SizedBox(height: 40),
            ],
          ),
    );
  }

  
  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 8,
        width: _currentStep == index ? 24 : 8,
        decoration: BoxDecoration(
          color: _currentStep == index ? const Color(0xFF2D5A27) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      )),
    );
  }

  Widget _buildStepName() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mulai dari nama kamu dulu,", style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("Panggilannya siapa nih?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0A4D41))),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
              hintText: "Nama kamu...",
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2D5A27), width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPhoto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          const Text("Biar profil kamu lebih personal,", style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("Pasang foto profil yuk!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0A4D41))),
          const SizedBox(height: 50),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null ? const Icon(Icons.person_add_rounded, size: 50, color: Colors.grey) : null,
                ),
                Positioned(
                  bottom: 5, right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF2D5A27), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (_currentStep == 0) {
              if (_nameController.text.isNotEmpty) {
                FocusScope.of(context).unfocus(); 
                setState(() => _currentStep = 1);
                _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              }
            } else {
              _finishSetup();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D5A27),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(_currentStep == 0 ? "LANJUT" : "SELESAI", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}