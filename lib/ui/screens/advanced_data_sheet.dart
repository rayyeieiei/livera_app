import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livera_app/main.dart'; 
import 'package:livera_app/ui/screens/subscription.plan.screen.dart'; 

class AdvancedDataSheet extends StatelessWidget {
  // 🔥 KITA BIKIN KOTAK PENERIMA PAKET DATA DARI DASHBOARD JIR!
  final double currentPh;
  final double currentTemp;
  final double currentAirflow;
  final double currentLight;
  final int nutriN;
  final int nutriP;
  final int nutriK;

  // Wajib diisi pas dipanggil dari dashboard
  const AdvancedDataSheet({
    super.key,
    required this.currentPh,
    required this.currentTemp,
    required this.currentAirflow,
    required this.currentLight,
    required this.nutriN,
    required this.nutriP,
    required this.nutriK,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ambil status VIP dari provider lu, bray!
    final userProvider = Provider.of<UserProvider>(context);
    final isPremium = userProvider.isPremium;
    
    // (Gak perlu narik data sensor dari provider lagi, karena udah dikirim dari dashboard)
    
    const Color textColor = Color(0xFF0B2A12);
    const Color primaryGreen = Color(0xFF2D5A27);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Advanced Parameters", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              children: [
                _buildSectionTitle("Water & Ecosystem", Icons.water_drop_outlined, Colors.blue),
                const SizedBox(height: 12),
                _buildDataGrid([
                  // 🔥 PAKAI VARIABEL YANG UDAH DIKIRIM DARI DASHBOARD JIR
                  _buildDataCard("Acidity (pH)", currentPh.toStringAsFixed(1), currentPh >= 6.5 && currentPh <= 8.5 ? "Stable" : "Warning", Icons.science_outlined, Colors.blue),
                  _buildDataCard("Water Temp", "${currentTemp.toStringAsFixed(1)}°C", "Optimal", Icons.thermostat_outlined, Colors.teal),
                  _buildDataCard("Water Level", "85%", "Sufficient", Icons.waves_outlined, Colors.cyan),
                ]),
                
                const SizedBox(height: 24),
                _buildSectionTitle("Hardware Diagnostics", Icons.memory_outlined, Colors.orange),
                const SizedBox(height: 12),
                _buildDataGrid([
                  _buildDataCard("Fan Speed", "${currentAirflow.toStringAsFixed(0)}", "RPM", Icons.air_outlined, Colors.orange),
                  _buildDataCard("PAR Intensity", "${currentLight.toStringAsFixed(0)}", "µmol/m²/s", Icons.light_mode_outlined, Colors.amber),
                  _buildDataCard("Sys Voltage", "11.8V", "Normal", Icons.electrical_services_outlined, Colors.deepOrange),
                ]),

                const SizedBox(height: 24),
                _buildSectionTitle("Nutrient Breakdown", Icons.eco_outlined, primaryGreen),
                const SizedBox(height: 12),
                
                isPremium 
                    ? _buildDataGrid([
                        _buildDataCard("Nitrogen (N)", "$nutriN%", "Level", Icons.grass_outlined, primaryGreen),
                        _buildDataCard("Phosphorus", "$nutriP%", "Level", Icons.spa_outlined, primaryGreen),
                        _buildDataCard("Potassium", "$nutriK%", "Level", Icons.forest_outlined, primaryGreen),
                      ])
                    : _buildLockedSection(context, primaryGreen), 
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B2A12))),
      ],
    );
  }

  Widget _buildDataGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: children,
    );
  }

  Widget _buildDataCard(String title, String value, String subtitle, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B2A12)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: iconColor, fontWeight: FontWeight.bold), maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildLockedSection(BuildContext context, Color primaryGreen) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.4,
            child: _buildDataGrid([
              _buildDataCard("Nitrogen (N)", "???", "Locked", Icons.grass_outlined, Colors.grey),
              _buildDataCard("Phosphorus", "???", "Locked", Icons.spa_outlined, Colors.grey),
              _buildDataCard("Potassium", "???", "Locked", Icons.forest_outlined, Colors.grey),
            ]),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: const Icon(Icons.lock_rounded, color: Color(0xFFD4AF37), size: 24),
              ),
              const SizedBox(height: 8),
              const Text("Unlock Deep Analytics with LIVERA VIP", style: TextStyle(color: Color(0xFF0B2A12), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionPlanScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text("Upgrade Now", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}