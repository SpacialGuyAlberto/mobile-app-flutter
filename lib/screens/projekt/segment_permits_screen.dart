import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SegmentPermitsScreen extends StatefulWidget {
  final String segmentId;
  const SegmentPermitsScreen({Key? key, required this.segmentId}) : super(key: key);

  @override
  State<SegmentPermitsScreen> createState() => _SegmentPermitsScreenState();
}

class _SegmentPermitsScreenState extends State<SegmentPermitsScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<dynamic> _permits = [];

  @override
  void initState() {
    super.initState();
    _fetchPermits();
  }

  Future<void> _fetchPermits() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://fedora.fritz.box:8080/api/v1/segments/${widget.segmentId}/permits'));
      if (response.statusCode == 200) {
        setState(() {
          _permits = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching permits: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPermit() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://fedora.fritz.box:8080/api/v1/segments/${widget.segmentId}/permits'),
        );
        request.files.add(await http.MultipartFile.fromPath('file', result.files.single.path!));
        var response = await request.send();

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permit uploaded successfully'), backgroundColor: Colors.green),
            );
          }
          _fetchPermits();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload permit'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131415),
      appBar: AppBar(
        title: Text('Permits for Segment #${widget.segmentId}', style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF1C1D21),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_isUploading) 
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: LinearProgressIndicator(color: Color(0xFF6938EF)),
                  ),
                Expanded(
                  child: _permits.isEmpty 
                    ? const Center(
                        child: Text('No permits found for this segment.', 
                        style: TextStyle(color: Colors.white54, fontSize: 16)))
                    : ListView.builder(
                        itemCount: _permits.length,
                        itemBuilder: (context, index) {
                          final permit = _permits[index];
                          // Map fedora.fritz.box to Android Emulator local IP if needed
                          final pdfUrl = permit['pdfUrl']?.toString().replaceAll('fedora.fritz.box', 'fedora.fritz.box');
                          final previewUrl = permit['previewImageUrl']?.toString().replaceAll('fedora.fritz.box', 'fedora.fritz.box');
                          return Card(
                            color: const Color(0xFF1C1D21),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                                  ),
                                  title: Text(permit['name'] ?? 'Permit Document', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text(permit['createdAt'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download, color: Colors.blueAccent),
                                    onPressed: () async {
                                      if (pdfUrl != null) {
                                        final uri = Uri.parse(pdfUrl);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      }
                                    },
                                  ),
                                ),
                                if (previewUrl != null && previewUrl.isNotEmpty)
                                  GestureDetector(
                                    onTap: () async {
                                      if (pdfUrl != null) {
                                        final uri = Uri.parse(pdfUrl);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      }
                                    },
                                    child: Container(
                                      height: 250,
                                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          previewUrl,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.topCenter,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.broken_image, color: Colors.white30, size: 40),
                                          ),
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6938EF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text('UPLOAD PDF PERMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    onPressed: _isUploading ? null : _uploadPermit,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
