import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/offline_downloader_provider.dart';
import '../../providers/sync_providers.dart';

class OfflineSyncScreen extends ConsumerStatefulWidget {
  const OfflineSyncScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends ConsumerState<OfflineSyncScreen> {
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offlineDownloaderProvider);
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Synchronization'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF111827),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_download_outlined, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'Download Project for Offline Use',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a project to download all its data (Clusters, Segments, POPs, etc.) to your phone. You will be able to view and work on it without an internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return const Text('No projects available', style: TextStyle(color: Colors.white));
                }
                return DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  dropdownColor: const Color(0xFF1F2937),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Select Project',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF1F2937),
                  ),
                  items: projects.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  onChanged: state.isDownloading
                      ? null
                      : (val) {
                          setState(() {
                            _selectedProjectId = val;
                          });
                        },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: (_selectedProjectId == null || state.isDownloading)
                  ? null
                  : () {
                      ref.read(offlineDownloaderProvider.notifier).downloadProjectData(_selectedProjectId!);
                    },
              icon: state.isDownloading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download, color: Colors.white),
              label: Text(
                state.isDownloading ? 'DOWNLOADING...' : 'START DOWNLOAD',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            
            if (state.isDownloading || state.progress > 0) ...[
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: Colors.grey.withOpacity(0.2),
                color: Colors.greenAccent,
                minHeight: 8,
              ),
              const SizedBox(height: 16),
            ],

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
                    state.statusMessage.isEmpty ? 'Ready.' : state.statusMessage,
                    style: TextStyle(color: state.progress == 1.0 ? Colors.greenAccent : Colors.amberAccent, fontFamily: 'monospace'),
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
