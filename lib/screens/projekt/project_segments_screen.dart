import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../widgets/glass_card.dart';

class ProjectSegmentsScreen extends StatefulWidget {
  final String projectId;
  const ProjectSegmentsScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<ProjectSegmentsScreen> createState() => _ProjectSegmentsScreenState();
}

class _ProjectSegmentsScreenState extends State<ProjectSegmentsScreen> {
  late Future<List<dynamic>> _segmentsFuture;

  @override
  void initState() {
    super.initState();
    _segmentsFuture = _fetchSegments();
  }

  Future<List<dynamic>> _fetchSegments() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.178.57:8080/api/v1/planning/projects/${widget.projectId}/segments'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Project Segments', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
            child: FutureBuilder<List<dynamic>>(
              future: _segmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No segments found for this project.', style: TextStyle(color: Color(0xFF8A8F98))));
                }

                final segments = snapshot.data!;
                return ListView.builder(
                  itemCount: segments.length,
                  itemBuilder: (context, index) {
                    final segment = segments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          context.push('/segment_evidence/${segment['id']}');
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(segment['name'] ?? 'Unnamed Segment', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Icon(Icons.photo_camera, color: Colors.blueAccent, size: 20),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Length: ${segment['estimatedLength'] ?? 0}m', style: const TextStyle(color: Color(0xFF8A8F98), fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Status: ${segment['status'] ?? 'PLANNED'}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Go to map to create a segment for this project
          context.push('/create_segment/${widget.projectId}');
        },
        backgroundColor: Colors.greenAccent,
        icon: const Icon(Icons.add_location_alt, color: Colors.black),
        label: const Text('Create Segment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
