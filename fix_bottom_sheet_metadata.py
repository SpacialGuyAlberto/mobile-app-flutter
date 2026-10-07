import re

with open('lib/widgets/segment_edit_bottom_sheet.dart', 'r') as f:
    content = f.read()

old_func = """  Future<void> _loadMetadata() async {
    try {
      final crewsData = await ApiService().get('/crews');
      if (crewsData is List) setState(() => _availableCrews = crewsData);
      
      final popData = await ApiService().get('/pops');
      if (popData is List) setState(() => _pops = popData);
      
      final nvtData = await ApiService().get('/netzverteilers');
      if (nvtData is List) setState(() => _netzverteilers = nvtData);
      
      // Fallback if the id is not in the dynamically loaded list
      if (_selectedCrewId != null && !_availableCrews.any((c) => c['id']?.toString() == _selectedCrewId)) {
        _availableCrews.add({'id': _selectedCrewId!, 'name': 'Unknown Crew ($_selectedCrewId)'});
      }
    } catch (e) {
      print('Could not load metadata: $e');
    }
  }"""

new_func = """  Future<void> _loadMetadata() async {
    try {
      final crewsData = await ApiService().get('/crews');
      if (crewsData is List) setState(() => _availableCrews = crewsData);
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
      final nvtData = await ApiService().get('/netzverteilers');
      if (nvtData is List) setState(() => _netzverteilers = nvtData);
    } catch (e) {
      print('Could not load netzverteilers: $e');
    }
    
    // Fallback if the id is not in the dynamically loaded list
    if (_selectedCrewId != null && !_availableCrews.any((c) => c['id']?.toString() == _selectedCrewId)) {
      setState(() {
        _availableCrews.add({'id': _selectedCrewId!, 'name': 'Unknown Crew ($_selectedCrewId)'});
      });
    }
  }"""

if old_func in content:
    content = content.replace(old_func, new_func)
else:
    print("Could not find old_func exactly as specified")

with open('lib/widgets/segment_edit_bottom_sheet.dart', 'w') as f:
    f.write(content)
