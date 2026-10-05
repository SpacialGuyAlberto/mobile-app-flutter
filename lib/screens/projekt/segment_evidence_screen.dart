import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../widgets/glass_card.dart';

class SegmentEvidenceScreen extends StatefulWidget {
  final String segmentId;
  const SegmentEvidenceScreen({Key? key, required this.segmentId}) : super(key: key);

  @override
  State<SegmentEvidenceScreen> createState() => _SegmentEvidenceScreenState();
}

class _SegmentEvidenceScreenState extends State<SegmentEvidenceScreen> {
  bool _isUploading = false;
  String _lifecycleStage = 'EXCAVATION';

  Future<void> _uploadEvidence(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? media = await picker.pickImage(source: source);

    if (media == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Simulate Geolocation extraction & API request
      await Future.delayed(const Duration(seconds: 2));

      // In a real scenario:
      // 1. Read EXIF GPS data from the image.
      // 2. Validate against segment coordinates (geo-fencing).
      // 3. POST to /api/v1/field/segments/{segmentId}/evidence

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidence uploaded successfully. Geolocation verified (Trenching).'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Segment #${widget.segmentId} Lifecycle', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_road),
            tooltip: 'Edit Fencing Plan',
            onPressed: () {
              context.push('/edit_fencing_plan/${widget.segmentId}');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF131415), Color(0xFF1C1D21)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lifecycle Stage', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF2D2E33)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _lifecycleStage,
                      dropdownColor: const Color(0xFF1C1D21),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8A8F98)),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _lifecycleStage = newValue;
                          });
                        }
                      },
                      items: <String>['EXCAVATION', 'PIPE_LAYING', 'SURFACE_RESTORATION', 'TESTING']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.replaceAll('_', ' ')),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Upload Evidence', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Capture photo or video to document progress. The system will automatically check geolocation to ensure it matches the segment coordinates.',
                  style: TextStyle(color: Color(0xFF8A8F98), fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (_isUploading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          child: InkWell(
                            onTap: () => _uploadEvidence(ImageSource.camera),
                            child: const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.blueAccent, size: 48),
                                  SizedBox(height: 12),
                                  Text('Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassCard(
                          child: InkWell(
                            onTap: () => _uploadEvidence(ImageSource.gallery),
                            child: const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Icon(Icons.photo_library, color: Colors.purpleAccent, size: 48),
                                  SizedBox(height: 12),
                                  Text('Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
