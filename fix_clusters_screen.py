import re

with open('lib/screens/projekt/project_clusters_screen.dart', 'r') as f:
    content = f.read()

# Add import
content = content.replace("import 'package:go_router/go_router.dart';", "import 'package:go_router/go_router.dart';\nimport '../../core/network/api_service.dart';")

# Replace _ProjectClustersScreenState body up to build
state_body_new = """class _ProjectClustersScreenState extends State<ProjectClustersScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  String _projectName = 'Loading...';
  List<Map<String, dynamic>> _clusters = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      // Fetch project details
      final projectData = await api.get('/projects/${widget.projectId}');
      _projectName = projectData['name'] ?? 'Project ${widget.projectId}';

      // Fetch all clusters
      final clustersData = await api.get('/clusters');
      final allClusters = List<Map<String, dynamic>>.from(clustersData);
      
      // Filter by projectId
      final projectClusters = allClusters.where((c) => c['projectId'].toString() == widget.projectId.toString()).toList();
      
      // Calculate popCount and netzverteilerCount for the UI
      for (var c in projectClusters) {
        final pops = c['pops'] as List? ?? [];
        c['popCount'] = pops.length;
        int nvtCount = 0;
        for (var p in pops) {
          final nvts = p['nvts'] as List? ?? [];
          nvtCount += nvts.length;
        }
        c['netzverteilerCount'] = nvtCount;
        c['description'] = c['description'] ?? 'No description provided.';
        c['name'] = c['name'] ?? 'Cluster ${c['id']}';
      }

      if (mounted) {
        setState(() {
          _clusters = projectClusters;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading clusters: $e');
      if (mounted) {
        setState(() {
          _projectName = 'Project ${widget.projectId}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {"""

# Replace from `class _ProjectClustersScreenState ...` to `  Widget build(BuildContext context) {`
content = re.sub(r'class _ProjectClustersScreenState extends State<ProjectClustersScreen> \{\n  int _selectedTabIndex = 0;\n\n  @override\n  Widget build\(BuildContext context\) \{', state_body_new, content)

# Remove the mocked clusters list
content = re.sub(r"    // Mocked data mirroring the user's screenshot\n    final List<Map<String, dynamic>> clusters = \[\n(.*?)\n    \];\n\n", "", content, flags=re.DOTALL)

# Replace 'Fürth Dambach\nDeployment' with _projectName
content = content.replace("'Fürth Dambach\\nDeployment'", "_projectName")

# Replace ...clusters.map with ..._clusters.map
content = content.replace("...clusters.map", "..._clusters.map")

# Wrap the SingleChildScrollView with an _isLoading check
# We need to replace `body: SingleChildScrollView(` with `body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(`
content = content.replace("body: SingleChildScrollView(", "body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(")

with open('lib/screens/projekt/project_clusters_screen.dart', 'w') as f:
    f.write(content)
