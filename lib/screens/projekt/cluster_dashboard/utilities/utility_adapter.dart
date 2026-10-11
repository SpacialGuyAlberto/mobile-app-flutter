import 'package:flutter/material.dart';
import '../../../../models/utility_models.dart';
import '../models/cluster_element_item.dart';
import 'utility_info_sheet.dart';

/// Adapts UtilityLine entities into ClusterElementItem models for list display (Adapter & LSP).
class UtilityAdapter {
  static ClusterElementItem toElementItem(
    UtilityLine util, {
    required BuildContext context,
  }) {
    return ClusterElementItem(
      id: util.id?.toString() ?? '',
      name: '${util.utilityType} Line${util.operatorName != null ? " (${util.operatorName})" : ""}',
      status: util.status?.toUpperCase() ?? 'ACTIVE',
      type: ClusterElementType.utilities,
      originalModel: util,
      onTap: () => UtilityInfoSheet.show(context, util),
    );
  }

  static List<ClusterElementItem> toElementItems(
    List<UtilityLine> utilities, {
    required BuildContext context,
  }) {
    return utilities.map((util) => toElementItem(util, context: context)).toList();
  }
}
