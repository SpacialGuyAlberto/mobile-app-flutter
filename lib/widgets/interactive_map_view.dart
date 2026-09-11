import 'package:flutter/material.dart';

class InteractiveMapView extends StatelessWidget {
  const InteractiveMapView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: Color(0xFF2D2E33)),
        ),
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Stack(
            children: [
              // Map Background (Berlin)
              Positioned.fill(
                child: Image.network(
                  'https://i.imgur.com/G4h7R2Z.jpeg',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              
              // Project 1 Marker (Berlin Deployment)
              _buildMapMarker(top: 80, left: 120, icon: Icons.location_on, color: Colors.greenAccent, label: 'Project A'),
              
              // Project 2 Marker
              _buildMapMarker(top: 150, left: 220, icon: Icons.location_on, color: Colors.blueAccent, label: 'Project B'),

              // Segment (Risk)
              _buildMapMarker(top: 120, left: 180, icon: Icons.warning_amber_rounded, color: Colors.redAccent, label: 'Risk #402'),

              // Crew
              _buildMapMarker(top: 200, left: 100, icon: Icons.engineering, color: Colors.orangeAccent, label: 'Crew Alpha'),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapMarker({required double top, required double left, required IconData icon, required Color color, required String label}) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Icon(icon, color: color, size: 28),
        ],
      ),
    );
  }
}
