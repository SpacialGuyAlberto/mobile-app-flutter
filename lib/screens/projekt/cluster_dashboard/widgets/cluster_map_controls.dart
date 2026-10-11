import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/ar_companion_provider.dart';

/// Floating action buttons and overlays on top of the interactive map (SRP compliant).
class ClusterMapControls extends StatelessWidget {
  final String projectId;
  final bool is3DMode;
  final bool isPanelVisible;
  final bool isOffline;
  final bool isDownloading;
  final bool isMapEditMode;
  final String? activeDrawTool;
  final VoidCallback onMyLocation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onStreetView;
  final VoidCallback onToggle3D;
  final VoidCallback onTogglePanel;
  final VoidCallback onDownloadOfflineMap;
  final VoidCallback onCancelDraw;

  const ClusterMapControls({
    super.key,
    required this.projectId,
    required this.is3DMode,
    required this.isPanelVisible,
    required this.isOffline,
    required this.isDownloading,
    required this.isMapEditMode,
    required this.activeDrawTool,
    required this.onMyLocation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onStreetView,
    required this.onToggle3D,
    required this.onTogglePanel,
    required this.onDownloadOfflineMap,
    required this.onCancelDraw,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isOffline)
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'MODO OFFLINE',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // Action Buttons on Map
        Positioned(
          top: 100,
          right: 16,
          child: Column(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final arState = ref.watch(arCompanionProvider);
                  return FloatingActionButton(
                    heroTag: 'arCompanionBtn',
                    mini: true,
                    backgroundColor: arState.isBroadcasting ? const Color(0xFF6938EF) : const Color(0xFF1C1D21),
                    onPressed: () async {
                      final notifier = ref.read(arCompanionProvider.notifier);
                      int? projId = int.tryParse(projectId);
                      if (projId != null) notifier.setProjectId(projId);

                      if (arState.isBroadcasting) {
                        notifier.stopBroadcasting();
                      } else {
                        final error = await notifier.startBroadcasting(arState.targetIp, arState.targetPort);
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Icon(
                      arState.isBroadcasting ? Icons.cast_connected : Icons.cast,
                      color: arState.isBroadcasting ? Colors.white : Colors.blueAccent,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'locateMeBtn',
                mini: true,
                backgroundColor: const Color(0xFF1C1D21),
                onPressed: onMyLocation,
                child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'zoomInBtn',
                mini: true,
                backgroundColor: const Color(0xFF1C1D21),
                onPressed: onZoomIn,
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoomOutBtn',
                mini: true,
                backgroundColor: const Color(0xFF1C1D21),
                onPressed: onZoomOut,
                child: const Icon(Icons.remove, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 24),
              FloatingActionButton(
                heroTag: 'svBtn',
                mini: true,
                backgroundColor: const Color(0xFF1C1D21),
                onPressed: onStreetView,
                child: const Icon(Icons.directions_walk, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: '3dBtn',
                mini: true,
                backgroundColor: is3DMode ? const Color(0xFF6938EF) : const Color(0xFF1C1D21),
                onPressed: onToggle3D,
                child: const Icon(Icons.threed_rotation, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'panelBtn',
                mini: true,
                backgroundColor: isPanelVisible ? const Color(0xFF1C1D21) : const Color(0xFF6938EF),
                onPressed: onTogglePanel,
                child: Icon(isPanelVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white, size: 20),
              ),
              if (!isOffline) ...[
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'downloadMapBtn',
                  mini: true,
                  backgroundColor: isDownloading ? Colors.grey : const Color(0xFF1C1D21),
                  onPressed: isDownloading ? null : onDownloadOfflineMap,
                  child: isDownloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_for_offline, color: Colors.greenAccent, size: 20),
                ),
              ],
            ],
          ),
        ),

        // Active Draw Tool banner
        if (isMapEditMode && activeDrawTool != null)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6938EF),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap on the map to place $activeDrawTool',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: onCancelDraw,
                    child: const Icon(Icons.close, color: Colors.white),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
}
