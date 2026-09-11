import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/services/voice_service.dart';

class CreateWorkLogScreen extends StatefulWidget {
  const CreateWorkLogScreen({Key? key}) : super(key: key);

  @override
  State<CreateWorkLogScreen> createState() => _CreateWorkLogScreenState();
}

class _CreateWorkLogScreenState extends State<CreateWorkLogScreen> {
  final TextEditingController _depthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  
  String _selectedCable = 'Select Cable Type';
  String _selectedSoil = 'Select Soil Type';
  bool _isScanning = false;
  bool _isListening = false;

  final ImagePicker _picker = ImagePicker();
  final Map<String, XFile?> _capturedImages = {
    'Excavation': null,
    'GPS Device': null,
    'Wiring': null,
    'Fencing': null,
  };

  Future<void> _takePicture(String category) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (photo != null) {
        setState(() {
          _capturedImages[category] = photo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open camera.'), backgroundColor: Colors.redAccent),
      );
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
            _notesController.text = text;
          });
        });
      }
    }
  }

  void _simulateAIScan() async {
    bool hasPhoto = _capturedImages.values.any((file) => file != null);
    if (!hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least one evidence photo first!'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _depthController.text = '60'; 
      _widthController.text = '30'; 
      _selectedCable = '144-core Fiber';
      _selectedSoil = 'Rocky / Compact';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('New Trench Log'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('FIELD EVIDENCE (REQUIRED FOR AI)', style: theme.textTheme.labelSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildEvidenceCard('Excavation', Icons.terrain),
                    const SizedBox(width: 12),
                    _buildEvidenceCard('GPS Device', Icons.gps_fixed),
                    const SizedBox(width: 12),
                    _buildEvidenceCard('Wiring', Icons.cable),
                    const SizedBox(width: 12),
                    _buildEvidenceCard('Fencing', Icons.fence),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI Scan Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 32),
                    const SizedBox(height: 16),
                    Text('QuarkBau AI Vision', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Upload photos above and run the AI Auto-Scan to detect depth, width, and materials.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                        ),
                        icon: _isScanning 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                        label: Text(_isScanning ? 'ANALYZING...' : 'START AI AUTO-SCAN'),
                        onPressed: _isScanning ? null : _simulateAIScan,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Text('MANUAL OVERRIDE', style: theme.textTheme.labelSmall),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Depth (cm)', _depthController, Icons.height)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Width (cm)', _widthController, Icons.swap_horiz)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown('Cable Type', _selectedCable, ['Select Cable Type', 'Microduct (HDPE)', '144-core Fiber', '288-core Fiber'], Icons.cable, (val) {
                      if (val != null) setState(() => _selectedCable = val);
                    }),
                    const SizedBox(height: 16),
                    _buildDropdown('Soil Condition', _selectedSoil, ['Select Soil Type', 'Normal / Soft', 'Rocky / Compact', 'Asphalt / Concrete'], Icons.landscape, (val) {
                      if (val != null) setState(() => _selectedSoil = val);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('NOTES (VOICE ENABLED)', style: theme.textTheme.labelSmall),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isListening ? AppTheme.primaryColor : AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Tap mic to dictate...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.stop_circle : Icons.mic),
                      color: _isListening ? Colors.redAccent : AppTheme.textMuted,
                      iconSize: 32,
                      onPressed: _toggleListening,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Work Log Submitted Successfully!'), backgroundColor: Colors.green),
                  );
                  context.pop();
                },
                child: const Text('SUBMIT WORK LOG'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceCard(String label, IconData defaultIcon) {
    final XFile? imageFile = _capturedImages[label];
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _takePicture(label),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Stack(
          children: [
            if (imageFile != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imageFile.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (imageFile != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black54,
                  ),
                ),
              ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    imageFile != null ? Icons.check_circle : defaultIcon,
                    color: imageFile != null ? Colors.green : AppTheme.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: imageFile != null ? Colors.white : AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, IconData icon, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppTheme.cardElevated,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
