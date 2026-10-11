import 'package:flutter/material.dart';
import '../../../../widgets/glass_card.dart';
import '../models/cluster_element_item.dart';

/// Renders the statistics cards for cluster element types (SRP compliant).
class ClusterStatsGrid extends StatelessWidget {
  final Map<String, int> stats;

  const ClusterStatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      children: [
        _buildStatCard('POPs', stats['POP'] ?? 0, ClusterElementType.pop.color),
        _buildStatCard('Netzverteiler', stats['Netzverteiler'] ?? 0, ClusterElementType.netzverteiler.color),
        _buildStatCard('Segments', stats['Segments'] ?? 0, ClusterElementType.segments.color),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.circle, color: color, size: 12),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
