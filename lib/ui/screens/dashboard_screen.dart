import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Kita buat konstanta warna biar konsisten
  final Color primaryGreen = const Color(0xFF2D5A27);
  final Color sageGreen = const Color(0xFF82A881);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // Biar bisa di-scroll kalau layar HP pendek
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildMainStatusCard(),
                    const SizedBox(height: 20),
                    _buildEcosystemGrid(),
                    const SizedBox(height: 20),
                    _buildEnvironmentalParams(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // 1. HEADER section
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/logohuruf.png', height: 30),
          const CircleAvatar(
            backgroundColor: Color(0xFFE91E63),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 2. MAIN CARD (Photobioreactor Status)
  Widget _buildMainStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Photobioreactor Status', 
                style: TextStyle(color: Colors.white70, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Active', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('87%', 
            style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const Text('Growth Efficiency', 
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  // 3. ECOSYSTEM GRID (Temp, O2, pH, Biomass)
  Widget _buildEcosystemGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ecosystem Care', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _buildSmallStatCard('Temp', '28°C', 'Stable', Colors.blue),
            _buildSmallStatCard('O₂ Level', '95%', 'Optimal', Colors.cyan),
            _buildSmallStatCard('pH Level', '7.2', 'Optimal', Colors.purple),
            _buildSmallStatCard('Biomass', '2.4 g/L', '+5%', Colors.pink),
          ],
        ),
      ],
    );
  }

  // 4. SMALL STAT CARD REUSABLE
  Widget _buildSmallStatCard(String title, String value, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 5. ENVIRONMENTAL PARAMS
  Widget _buildEnvironmentalParams() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Light Intensity', style: TextStyle(fontWeight: FontWeight.w500)),
          Text('450 μmol', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 6. BOTTOM NAV
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}