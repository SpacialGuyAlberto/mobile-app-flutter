import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/utility_models.dart';
import 'utility_map_renderer.dart';

/// Modal bottom sheet presenting details of a selected utility line (SRP compliant).
class UtilityInfoSheet extends StatelessWidget {
  final UtilityLine utility;

  const UtilityInfoSheet({
    super.key,
    required this.utility,
  });

  static Future<void> show(BuildContext context, UtilityLine utility) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1D21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => UtilityInfoSheet(utility: utility),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = UtilityMapRenderer.getUtilityColor(utility);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(_getUtilityIcon(), color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${utility.utilityType} LINE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${utility.id ?? "N/A"} • Status: ${utility.status ?? "ACTIVE"}',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (utility.hazardLevel != null)
                    _buildHazardBadge(utility.hazardLevel!),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              if (utility.operatorName != null)
                _buildInfoRow(Icons.business, 'Operator', utility.operatorName!),
              if (utility.depth != null)
                _buildInfoRow(Icons.vertical_align_bottom, 'Depth', '${utility.depth} m'),
              if (utility.contactPhone != null)
                _buildPhoneRow(context, utility.contactPhone!),

              ..._buildSpecificDetails(),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getUtilityIcon() {
    if (utility is WaterPipe) return Icons.water_drop;
    if (utility is GasPipe) return Icons.local_fire_department;
    if (utility is ElectricityCable) return Icons.bolt;
    return Icons.alt_route;
  }

  Widget _buildHazardBadge(String level) {
    Color badgeColor = Colors.orange;
    if (level.toUpperCase() == 'HIGH') badgeColor = Colors.redAccent;
    if (level.toUpperCase() == 'LOW') badgeColor = Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$level HAZARD',
        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(BuildContext context, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Icon(Icons.phone, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 12),
          const Text('Contact: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(
            child: Text(
              phone,
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.greenAccent, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpecificDetails() {
    final list = <Widget>[];
    final util = utility;

    if (util is WaterPipe) {
      if (util.pipeType != null) list.add(_buildInfoRow(Icons.tune, 'Pipe Type', util.pipeType!));
      if (util.material != null) list.add(_buildInfoRow(Icons.category, 'Material', util.material!));
      if (util.diameterMm != null) list.add(_buildInfoRow(Icons.circle_outlined, 'Diameter', '${util.diameterMm} mm'));
      if (util.pressureLevel != null) list.add(_buildInfoRow(Icons.speed, 'Pressure', util.pressureLevel!));
    } else if (util is GasPipe) {
      if (util.pressureClass != null) list.add(_buildInfoRow(Icons.speed, 'Pressure Class', util.pressureClass!));
      if (util.material != null) list.add(_buildInfoRow(Icons.category, 'Material', util.material!));
    } else if (util is ElectricityCable) {
      if (util.voltageCategory != null) list.add(_buildInfoRow(Icons.electrical_services, 'Category', util.voltageCategory!));
      if (util.voltageValue != null) list.add(_buildInfoRow(Icons.flash_on, 'Voltage', '${util.voltageValue} V'));
      if (util.shieldingType != null) list.add(_buildInfoRow(Icons.shield, 'Shielding', util.shieldingType!));
      if (util.numberOfCores != null) list.add(_buildInfoRow(Icons.linear_scale, 'Cores', '${util.numberOfCores}'));
    }

    return list;
  }
}
