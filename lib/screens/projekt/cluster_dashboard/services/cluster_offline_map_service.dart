import 'dart:io';
import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Service dedicated to offline map checking and persistence (SRP compliant).
class ClusterOfflineMapService {
  Future<bool> checkIsOffline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isEmpty || result[0].rawAddress.isEmpty;
    } on SocketException catch (_) {
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<File?> getOfflineMapFile(String clusterId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/cluster_map_$clusterId.png');
      if (await file.exists()) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  Future<File?> saveMapSnapshot(GoogleMapController controller, String clusterId) async {
    final Uint8List? snapshot = await controller.takeSnapshot();
    if (snapshot == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cluster_map_$clusterId.png');
    await file.writeAsBytes(snapshot);
    return file;
  }
}
