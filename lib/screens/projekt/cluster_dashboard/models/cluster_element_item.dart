import 'package:flutter/material.dart';

/// Represents the category and styling of a cluster infrastructure element (OCP compliant).
class ClusterElementType {
  final String key;
  final String label;
  final Color color;
  final IconData icon;

  const ClusterElementType({
    required this.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  static const pop = ClusterElementType(
    key: 'POP',
    label: 'POP',
    color: Color(0xFF6938EF),
    icon: Icons.business,
  );

  static const netzverteiler = ClusterElementType(
    key: 'Netzverteiler',
    label: 'Netzverteiler',
    color: Color(0xFF2FB080),
    icon: Icons.dns,
  );

  static const segments = ClusterElementType(
    key: 'Segments',
    label: 'Segments',
    color: Color(0xFFFBBF24),
    icon: Icons.linear_scale,
  );

  static const utilities = ClusterElementType(
    key: 'Utilities',
    label: 'Utilities',
    color: Colors.grey,
    icon: Icons.alt_route,
  );

  static const acometidas = ClusterElementType(
    key: 'Acometidas',
    label: 'Acometidas',
    color: Color(0xFFF59E0B),
    icon: Icons.home,
  );

  static const List<ClusterElementType> all = [
    pop,
    netzverteiler,
    segments,
    utilities,
  ];

  static ClusterElementType fromKey(String key) {
    return all.firstWhere(
      (element) => element.key.toLowerCase() == key.toLowerCase(),
      orElse: () => ClusterElementType(
        key: key,
        label: key,
        color: Colors.white,
        icon: Icons.circle,
      ),
    );
  }
}

/// Common representation of a cluster element for list/accordion display (LSP compliant).
class ClusterElementItem {
  final String id;
  final String name;
  final String status;
  final ClusterElementType type;
  final dynamic originalModel;
  final VoidCallback? onTap;

  const ClusterElementItem({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    this.originalModel,
    this.onTap,
  });
}
