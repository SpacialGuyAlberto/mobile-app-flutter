import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ar_companion_provider.dart';

class ARCompanionScreen extends ConsumerStatefulWidget {
  const ARCompanionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ARCompanionScreen> createState() => _ARCompanionScreenState();
}

class _ARCompanionScreenState extends ConsumerState<ARCompanionScreen> {
  final _ipController = TextEditingController(text: '192.168.178.X'); // ¡Escribe aquí la IP de tus gafas!
  final _portController = TextEditingController(text: '8000');

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
      body: Padding(
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
              'This screen will read high-precision GPS data from your phone and stream it in real-time over the local network via UDP to the Unreal Engine application running on the AR headset.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
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
              onPressed: () {
                if (state.isBroadcasting) {
                  ref.read(arCompanionProvider.notifier).stopBroadcasting();
                } else {
                  final ip = _ipController.text;
                  final port = int.tryParse(_portController.text) ?? 8000;
                  ref.read(arCompanionProvider.notifier).startBroadcasting(ip, port);
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
