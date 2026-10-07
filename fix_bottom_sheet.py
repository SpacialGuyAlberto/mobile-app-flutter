import re

with open('lib/widgets/segment_edit_bottom_sheet.dart', 'r') as f:
    content = f.read()

# Add import
content = content.replace("import '../screens/projekt/segment_permits_screen.dart';", "import '../screens/projekt/segment_permits_screen.dart';\nimport '../core/network/api_service.dart';")

# State variables
content = re.sub(
    r'  final List<Map<String, String>> _availableCrews = \[.*?\];',
    r'''  List<dynamic> _availableCrews = [];
  List<dynamic> _pops = [];
  List<dynamic> _netzverteilers = [];
  
  String? _startNvtId;
  String? _endNvtId;
  String? _connectedPopId;''',
    content, flags=re.DOTALL
)

# Remove old NVT and POP controllers declaration
content = re.sub(r'  late TextEditingController _startNvtIdController;\n  late TextEditingController _endNvtIdController;\n  late TextEditingController _connectedPopIdController;\n', '', content)

# InitState modifications
init_state_replacement = '''
    _ductDiameterController = TextEditingController(text: widget.segment['ductDiameter']?.toString() ?? '');
    _streetNameController = TextEditingController(text: widget.segment['streetName']?.toString() ?? '');
    _streetTypeController = TextEditingController(text: widget.segment['streetType']?.toString() ?? '');
    _soilTypeController = TextEditingController(text: widget.segment['soilType']?.toString() ?? '');
    _lengthController = TextEditingController(text: widget.segment['length']?.toString() ?? '');
    _trafficLevelController = TextEditingController(text: widget.segment['trafficLevel']?.toString() ?? '');
    _startAddressController = TextEditingController(text: widget.segment['startAddress']?.toString() ?? '');
    _endAddressController = TextEditingController(text: widget.segment['endAddress']?.toString() ?? '');
    
    _startNvtId = widget.segment['startNvtId']?.toString();
    _endNvtId = widget.segment['endNvtId']?.toString();
    _connectedPopId = widget.segment['connectedPopId']?.toString();
    
    _loadMetadata();
'''
content = re.sub(
    r'    _ductDiameterController = TextEditingController.*?_connectedPopIdController = TextEditingController\(text: widget\.segment\[\'connectedPopId\'\]\?\.toString\(\) \?\? \'\'\);\n',
    init_state_replacement,
    content, flags=re.DOTALL
)

# Load Metadata method
load_metadata = '''
  Future<void> _loadMetadata() async {
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
  }
'''
content = content.replace('  @override\n  void dispose() {', load_metadata + '\n  @override\n  void dispose() {')

# Remove old controllers from dispose
content = re.sub(r'    _startNvtIdController\.dispose\(\);\n    _endNvtIdController\.dispose\(\);\n    _connectedPopIdController\.dispose\(\);\n', '', content)

# Remove crew fallback check in initState (since we moved it to _loadMetadata)
content = re.sub(r'    // Fallback if the id is not in the list\n    if \(_selectedCrewId != null && !_availableCrews\.any\(\(c\) => c\[\'id\'\] == _selectedCrewId\)\) \{\n      _availableCrews\.add\(\{\'id\': _selectedCrewId!, \'name\': \'Unknown Crew \(\$_selectedCrewId\)\'\}\);\n    \}\n', '', content)

# Save changes update
content = content.replace("'startNvtId': _startNvtIdController.text,", "'startNvtId': _startNvtId,")
content = content.replace("'endNvtId': _endNvtIdController.text,", "'endNvtId': _endNvtId,")
content = content.replace("'connectedPopId': _connectedPopIdController.text,", "'connectedPopId': _connectedPopId,")

# UI update
ui_replacement = '''
                  _buildTextField('Start Address', _startAddressController),
                  _buildTextField('End Address', _endAddressController),
                  
                  _buildDynamicDropdown('Start NVT', _startNvtId, _netzverteilers, (val) => setState(() => _startNvtId = val)),
                  _buildDynamicDropdown('End NVT', _endNvtId, _netzverteilers, (val) => setState(() => _endNvtId = val)),
                  _buildDynamicDropdown('Connected POP', _connectedPopId, _pops, (val) => setState(() => _connectedPopId = val)),
'''
content = re.sub(
    r'                  _buildTextField\(\'Start Address\', _startAddressController\);\n                  _buildTextField\(\'End Address\', _endAddressController\);\n                  _buildTextField\(\'Start NVT ID\', _startNvtIdController\);\n                  _buildTextField\(\'End NVT ID\', _endNvtIdController\);\n                  _buildTextField\(\'Connected POP ID\', _connectedPopIdController\);',
    ui_replacement,
    content
)

# Crew dropdown update in build
crew_dropdown_replacement = '''
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('None', style: TextStyle(color: Colors.white54))),
                              ..._availableCrews.map((crew) => DropdownMenuItem<String>(value: crew['id']?.toString(), child: Text(crew['name'] ?? 'Unknown Crew'))).toList(),
                            ],
'''
content = re.sub(
    r'                            items: \[\n                              const DropdownMenuItem<String>\(value: null, child: Text\(\'None\'\)\),\n                              \.\.\._availableCrews\.map\(\(crew\) => DropdownMenuItem\(value: crew\[\'id\'\], child: Text\(crew\[\'name\'\]!\)\)\)\.toList\(\),\n                            \],',
    crew_dropdown_replacement,
    content
)

# Add _buildDynamicDropdown method
build_dynamic_dropdown = '''
  Widget _buildDynamicDropdown(String label, String? value, List<dynamic> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('-- None --', style: TextStyle(color: Colors.white54))),
                ...items.map((item) {
                  final idStr = item['id']?.toString();
                  final nameStr = item['identifier'] ?? item['name'] ?? item['id']?.toString() ?? 'Unknown';
                  return DropdownMenuItem<String?>(
                    value: idStr,
                    child: Text(nameStr),
                  );
                }).toList(),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {'''

content = content.replace('  Widget _buildTextField(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {', build_dynamic_dropdown)

with open('lib/widgets/segment_edit_bottom_sheet.dart', 'w') as f:
    f.write(content)

