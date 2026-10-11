import 'package:flutter/material.dart';
import '../../../../models/planning/geometry_point.dart';
import '../../../../widgets/glass_card.dart';
import '../geometry/segment_geometry_service.dart';

/// Overlay GlassCard displaying real-time vector metrics and spline sharpness controls (SRP).
class VectorAnalyticsCard extends StatelessWidget {
  final List<GeometryPoint> points;
  final double curveSharpness;
  final bool isExpanded;
  final ValueChanged<bool> onToggleExpand;
  final ValueChanged<double> onSharpnessChanged;

  const VectorAnalyticsCard({
    super.key,
    required this.points,
    required this.curveSharpness,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSharpnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    final totalLength = SegmentGeometryService.calculateTotalLength(points, curveSharpness);
    final metrics = SegmentGeometryService.calculateVectorMetrics(points);

    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: GlassCard(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'VECTOR ANALYTICS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Total: ${totalLength.toStringAsFixed(2)}m',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => onToggleExpand(!isExpanded),
                        child: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Curve Sharpness (R):', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Expanded(
                      child: Slider(
                        value: curveSharpness,
                        min: 0.1,
                        max: 1.5,
                        activeColor: Colors.pinkAccent,
                        onChanged: onSharpnessChanged,
                      ),
                    ),
                    Text(
                      curveSharpness.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.pinkAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: metrics.length,
                    itemBuilder: (context, index) {
                      final m = metrics[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent.withValues(alpha: 0.2),
                                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'V${m.index}',
                                style: const TextStyle(
                                  color: Colors.pinkAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${m.distance.toStringAsFixed(2)}m',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.slopePercent == 0
                                      ? '0.00%'
                                      : (m.slopePercent > 0
                                          ? '▲ ${m.slopePercent.toStringAsFixed(2)}%'
                                          : '▼ ${(-m.slopePercent).toStringAsFixed(2)}%'),
                                  style: TextStyle(
                                    color: m.slopePercent == 0
                                        ? Colors.white70
                                        : (m.slopePercent > 0 ? Colors.greenAccent : Colors.redAccent),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  'Z1: ${m.z1?.toStringAsFixed(1) ?? '0.0'}m, Z2: ${m.z2?.toStringAsFixed(1) ?? '0.0'}m',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
