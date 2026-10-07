import re

with open('lib/screens/projekt/create_segment_screen.dart', 'r') as f:
    content = f.read()

# Replace _loadMetadata
old_func = """  Future<void> _loadMetadata() async {
    try {
      final crewsData = await ApiService().get('/crews');
      if (crewsData is List) setState(() => _crews = crewsData);
      
      final popData = await ApiService().get('/pops');
      if (popData is List) setState(() => _pops = popData);
      
      if (widget.projectId != null) {
        final segmentData = await ApiService().get('/projects/${widget.projectId}/segments');
        if (segmentData is List) setState(() => _segmentsContext = segmentData);
      }
      
      final nvtData = await ApiService().get('/netzverteilers');
      if (nvtData is List) {
        setState(() => _netzverteilers = nvtData);
        if (widget.initialLat == null && _netzverteilers.isNotEmpty && _netzverteilers.first['latitude'] != null) {
          final target = LatLng(_netzverteilers.first['latitude'], _netzverteilers.first['longitude']);
          setState(() {
            _initialCamera = CameraPosition(target: target, zoom: 16.0);
          });
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialCamera));
        }
      }
      
      _buildContextElements();
    } catch (e) {
      print('Could not load metadata: $e');
    }
  }"""

new_func = """  Future<void> _loadMetadata() async {
    try {
      final crewsData = await ApiService().get('/crews');
      if (crewsData is List) setState(() => _crews = crewsData);
    } catch (e) {
      print('Could not load crews: $e');
    }
    
    try {
      final popData = await ApiService().get('/pops');
      if (popData is List) setState(() => _pops = popData);
    } catch (e) {
      print('Could not load pops: $e');
    }
    
    try {
      if (widget.projectId != null) {
        final segmentData = await ApiService().get('/projects/${widget.projectId}/segments');
        if (segmentData is List) setState(() => _segmentsContext = segmentData);
      }
    } catch (e) {
      print('Could not load segments: $e');
    }
    
    try {
      final nvtData = await ApiService().get('/netzverteilers');
      if (nvtData is List) {
        setState(() => _netzverteilers = nvtData);
        if (widget.initialLat == null && _netzverteilers.isNotEmpty && _netzverteilers.first['latitude'] != null) {
          final target = LatLng(_netzverteilers.first['latitude'], _netzverteilers.first['longitude']);
          setState(() {
            _initialCamera = CameraPosition(target: target, zoom: 16.0);
          });
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(_initialCamera));
        }
      }
    } catch (e) {
      print('Could not load netzverteilers: $e');
    }
    
    _buildContextElements();
  }"""

if old_func in content:
    content = content.replace(old_func, new_func)
else:
    print("Could not find old_func exactly as specified")

with open('lib/screens/projekt/create_segment_screen.dart', 'w') as f:
    f.write(content)
