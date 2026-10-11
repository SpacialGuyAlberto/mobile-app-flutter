import 'package:flutter/material.dart';
import '../models/cluster_element_item.dart';

/// Accordion view displaying network nodes categorized by type (SRP & LSP compliant).
class ClusterNodeAccordion extends StatelessWidget {
  final Map<String, List<ClusterElementItem>> groupedElements;
  final String expandedGroup;
  final ValueChanged<String> onToggleGroup;

  const ClusterNodeAccordion({
    super.key,
    required this.groupedElements,
    required this.expandedGroup,
    required this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: groupedElements.entries.map((entry) {
        final groupName = entry.key;
        final items = entry.value;
        final isExpanded = expandedGroup == groupName;
        final type = ClusterElementType.fromKey(groupName);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => onToggleGroup(isExpanded ? '' : groupName),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: items.isNotEmpty ? type.color : Colors.white, size: 10),
                      const SizedBox(width: 12),
                      Text(
                        groupName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${items.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'NO NODES FOUND',
                              style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
                            ),
                          ),
                        )
                      : Column(
                          children: items.map((item) => _buildNodeItem(item)).toList(),
                        ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNodeItem(ClusterElementItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${item.id}',
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNodeStatusBadge(item.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bgColor = const Color(0xFF2FB080).withValues(alpha: 0.1);
        textColor = const Color(0xFF2FB080);
        break;
      case 'ERROR':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        textColor = const Color(0xFFEF4444);
        break;
      case 'PLANNED':
      default:
        bgColor = Colors.white.withValues(alpha: 0.05);
        textColor = Colors.white54;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
