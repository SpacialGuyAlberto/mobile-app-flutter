import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth/user_role.dart';
import '../core/theme.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    List<Widget> menuItems = [];

    // Obrero specific
    if (authState.user?.role == UserRole.fieldExpert) {
      menuItems.addAll([
        _buildDrawerItem(context, Icons.map_outlined, 'My Segments (Map)', '/obrero_map'),
        _buildDrawerItem(context, Icons.work_outline, 'Work Logs', '/work_logs'),
        _buildDrawerItem(context, Icons.calendar_today, 'Schedule', '/schedule'),
      ]);
    }

    // Projekt (Project Manager) FULL SIDEBAR matching Web Dashboard
    if (authState.user?.role == UserRole.projectManager) {
      menuItems.addAll([
        _buildDrawerItem(context, Icons.home_outlined, 'Home (Command Center)', '/'),
        
        const Divider(color: Color(0xFF2D2E33)),
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text('Operations', style: TextStyle(color: Color(0xFF8A8F98), fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        _buildDrawerItem(context, Icons.map_outlined, 'Map View', '/'),
        _buildDrawerItem(context, Icons.account_tree_outlined, 'Workflows', '/'),
        _buildDrawerItem(context, Icons.calendar_month_outlined, 'Schedule', '/schedule'),
        _buildDrawerItem(context, Icons.public, 'GIS Viewer', '/'),
        _buildDrawerItem(context, Icons.warning_amber_rounded, 'Risks (AI)', '/risks'),
        _buildDrawerItem(context, Icons.trending_up, 'Progress', '/'),
        _buildDrawerItem(context, Icons.assignment_outlined, 'Requests (Permits)', '/'),
        
        const Divider(color: Color(0xFF2D2E33)),
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text('Field Management', style: TextStyle(color: Color(0xFF8A8F98), fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        _buildDrawerItem(context, Icons.engineering_outlined, 'Crews', '/crews'),
        
        const Divider(color: Color(0xFF2D2E33)),
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text('Inventory', style: TextStyle(color: Color(0xFF8A8F98), fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        _buildDrawerItem(context, Icons.inventory_2_outlined, 'Materials & Machinery', '/inventory'),
        
        const Divider(color: Color(0xFF2D2E33)),
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text('Administration', style: TextStyle(color: Color(0xFF8A8F98), fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        _buildDrawerItem(context, Icons.settings_outlined, 'Settings', '/'),
      ]);
    }

    // Bauleiter (Site Manager) specific
    if (authState.user?.role == UserRole.manager) {
      menuItems.addAll([
        _buildDrawerItem(context, Icons.map_outlined, 'Project Map (AI Extract)', '/bauleiter_map'),
        _buildDrawerItem(context, Icons.group_outlined, 'Field Crews', '/crews'),
        _buildDrawerItem(context, Icons.inventory_2_outlined, 'Inventory', '/inventory'),
      ]);
    }

    return Drawer(
      backgroundColor: AppTheme.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.cardDark,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: const Text('QB', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${authState.user?.firstName ?? ''} ${authState.user?.lastName ?? ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authState.user?.role.toString().split('.').last.toUpperCase() ?? '',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...menuItems,
                  const Divider(color: Color(0xFF2D2E33)),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text('Integration', style: TextStyle(color: Color(0xFF8A8F98), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  _buildDrawerItem(context, Icons.cloud_download_outlined, 'Download for Offline', '/offline_sync'),
                  _buildDrawerItem(context, Icons.sensors, 'AR Companion Mode', '/ar_companion'),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderLight, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      dense: true,
      onTap: () {
        Navigator.pop(context); // Close drawer first
        context.go(route);      // Then navigate
      },
    );
  }
}
