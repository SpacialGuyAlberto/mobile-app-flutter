import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ar_companion_provider.dart';
import '../../core/config/env_config.dart';

class ARCompanionScreen extends ConsumerStatefulWidget {
  const ARCompanionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ARCompanionScreen> createState() => _ARCompanionScreenState();
}

class _ARCompanionScreenState extends ConsumerState<ARCompanionScreen> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final currentTarget = ref.read(arCompanionProvider).targetIp;
    final currentPort = ref.read(arCompanionProvider).targetPort;
    _ipController = TextEditingController(
      text: currentTarget.isNotEmpty ? currentTarget : EnvConfig.glassesIp,
    );
    _portController = TextEditingController(
      text: currentPort > 0 ? currentPort.toString() : EnvConfig.headsetPort.toString(),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arCompanionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Headset GPS Companion'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF111827),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Connect to AR Headset (e.g. Meta Quest 3)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transmite en tiempo real el GPS y orientación de tu teléfono por red local (UDP) a las gafas Quest 3.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune, color: Color(0xFF6938EF), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Configuración de Red (.env)',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: state.isBroadcasting
                            ? null
                            : () {
                                _ipController.text = EnvConfig.glassesIp;
                                _portController.text = EnvConfig.headsetPort.toString();
                              },
                        child: const Text('Usar .env', style: TextStyle(color: Color(0xFF6938EF), fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('💻 Laptop / Backend: ${EnvConfig.laptopIp}:${EnvConfig.backendPort}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('🥽 Gafas AR (Quest 3): ${EnvConfig.glassesIp}:${EnvConfig.headsetPort}',
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              enabled: !state.isBroadcasting,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'AR Headset IP Address',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              enabled: !state.isBroadcasting,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'UDP Port',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                if (state.isBroadcasting) {
                  ref.read(arCompanionProvider.notifier).stopBroadcasting();
                } else {
                  final ip = _ipController.text.trim();
                  final port = int.tryParse(_portController.text.trim()) ?? EnvConfig.headsetPort;
                  await ref.read(arCompanionProvider.notifier).saveConfig(ip, port);
                  final error = await ref.read(arCompanionProvider.notifier).startBroadcasting(ip, port);
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              icon: Icon(
                state.isBroadcasting ? Icons.stop_circle : Icons.sensors,
                color: Colors.white,
              ),
              label: Text(
                state.isBroadcasting ? 'STOP BROADCASTING' : 'START BROADCASTING GPS',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.isBroadcasting ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (!state.isBroadcasting) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Primero inicia el Broadcasting GPS')),
                  );
                  return;
                }
                ref.read(arCompanionProvider.notifier).forceCalibration();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Señal de calibración forzada enviada a Unity')),
                );
              },
              icon: const Icon(Icons.compass_calibration),
              label: const Text('CALIBRAR CON UNITY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.lastMessage.isEmpty ? 'Waiting to start...' : state.lastMessage,
                    style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
