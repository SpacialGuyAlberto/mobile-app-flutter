import re

files = [
    'lib/screens/projekt/create_segment_screen.dart',
    'lib/widgets/segment_edit_bottom_sheet.dart'
]

for file in files:
    with open(file, 'r') as f:
        content = f.read()

    # Create Segment Screen uses _crews
    if '_crews' in content and not '_availableCrews' in content:
        old_block = """    try {
      final crewsData = await ApiService().get('/crews');
      if (crewsData is List) setState(() => _crews = crewsData);
    } catch (e) {
      print('Could not load crews: $e');
    }"""
        
        new_block = """    try {
      final crewsData = await ApiService().get('/crews');
      if (crewsData is List) setState(() => _crews = crewsData);
    } catch (e) {
      print('Could not load crews: $e');
      setState(() => _crews = [
        {'id': 1, 'name': 'Crew Alpha (Mock)'},
        {'id': 2, 'name': 'Crew Beta (Mock)'},
        {'id': 3, 'name': 'Crew Gamma (Mock)'},
      ]);
    }"""
        content = content.replace(old_block, new_block)

    # Bottom Sheet uses _availableCrews
    if '_availableCrews' in content:
        old_block = """    try {
      final crewsData = await ApiService().get('/crews');
      if (crewsData is List) setState(() => _availableCrews = crewsData);
    } catch (e) {
      print('Could not load crews: $e');
    }"""
        
        new_block = """    try {
      final crewsData = await ApiService().get('/crews');
      if (crewsData is List) setState(() => _availableCrews = crewsData);
    } catch (e) {
      print('Could not load crews: $e');
      setState(() => _availableCrews = [
        {'id': 1, 'name': 'Crew Alpha (Mock)'},
        {'id': 2, 'name': 'Crew Beta (Mock)'},
        {'id': 3, 'name': 'Crew Gamma (Mock)'},
      ]);
    }"""
        content = content.replace(old_block, new_block)

    with open(file, 'w') as f:
        f.write(content)

