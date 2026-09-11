import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/voice_service.dart';
import '../../core/network/sync_manager.dart';

class EvidenceCaptureScreen extends ConsumerStatefulWidget {
  final String segmentId;

  const EvidenceCaptureScreen({Key? key, required this.segmentId}) : super(key: key);

  @override
  ConsumerState<EvidenceCaptureScreen> createState() => _EvidenceCaptureScreenState();
}

class _EvidenceCaptureScreenState extends ConsumerState<EvidenceCaptureScreen> {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final VoiceService _voiceService = VoiceService();

  String? _photoPath;
  String _voiceNote = "";
  bool _isListening = false;
  bool _isSaving = false;

  Future<void> _takePhoto() async {
    final path = await _cameraService.takePhoto();
    if (path != null) {
      setState(() {
        _photoPath = path;
      });
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      bool init = await _voiceService.init();
      if (init) {
        setState(() => _isListening = true);
        _voiceService.startListening((text) {
          setState(() {
            _voiceNote = text;
          });
        });
      }
    }
  }

  Future<void> _saveEvidence() async {
    if (_photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please take a photo first.')));
      return;
    }

    setState(() => _isSaving = true);
    
    final position = await _locationService.getCurrentLocation();
    
    final evidenceData = {
      'segmentId': widget.segmentId,
      'photoPath': _photoPath,
      'latitude': position?.latitude ?? 0.0,
      'longitude': position?.longitude ?? 0.0,
      'timestamp': DateTime.now().toIso8601String(),
      'voiceNoteText': _voiceNote,
      'type': 'TRENCH_INSPECTION',
    };

    final syncManager = ref.read(syncManagerProvider);
    await syncManager.saveAndSyncEvidence(evidenceData);

    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidence saved offline and queued for sync.')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Evidence'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SEGMENT ID: \${widget.segmentId}', style: theme.textTheme.labelSmall),
            const SizedBox(height: 16),
            
            // Photo Area
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                  image: _photoPath != null 
                    ? DecorationImage(image: FileImage(File(_photoPath!)), fit: BoxFit.cover)
                    : null,
                ),
                child: _photoPath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, size: 48, color: Colors.white24),
                        const SizedBox(height: 8),
                        Text('Tap to take photo', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60)),
                      ],
                    )
                  : null,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Voice Note Area
            Text('VOICE NOTE', style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isListening ? AppTheme.primaryColor : AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _voiceNote.isEmpty ? 'Tap mic to dictate observations...' : _voiceNote,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _voiceNote.isEmpty ? Colors.white24 : Colors.white,
                        fontStyle: _voiceNote.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isListening ? Icons.stop_circle : Icons.mic),
                    color: _isListening ? Colors.redAccent : AppTheme.primaryColor,
                    iconSize: 32,
                    onPressed: _toggleListening,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveEvidence,
              icon: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
              label: Text(_isSaving ? 'SAVING...' : 'SAVE EVIDENCE'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
