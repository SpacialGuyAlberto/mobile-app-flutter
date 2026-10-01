import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../models/auth/user_role.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_layout.dart';
import '../screens/obrero/work_logs_screen.dart';
import '../screens/obrero/create_work_log_screen.dart';
import '../screens/obrero/schedule_screen.dart';
import '../screens/obrero/obrero_map_screen.dart';
import '../screens/projekt/projects_dashboard_screen.dart';
import '../screens/projekt/project_segments_screen.dart';
import '../screens/projekt/risk_dashboard_screen.dart';
import '../screens/obrero/evidence_capture_screen.dart';
import '../screens/projekt/create_segment_screen.dart';
import '../screens/projekt/segment_evidence_screen.dart';
import '../screens/projekt/project_clusters_screen.dart';
import '../screens/projekt/cluster_area_dashboard_screen.dart';
import '../screens/bauleiter/field_crews_screen.dart';
import '../screens/bauleiter/inventory_screen.dart';
import '../screens/bauleiter/bauleiter_map_screen.dart';
import '../screens/dashboard/ar_companion_screen.dart';
import '../screens/dashboard/offline_sync_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.uri.toString() == '/login';
      
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final authState = ref.watch(authProvider);
          final userRole = authState.user?.role;
          String title = 'QuarkBau';
          
          if (userRole == UserRole.fieldExpert) {
            if (state.matchedLocation == '/') title = 'My Segments';
            if (state.matchedLocation == '/obrero_map') title = 'My Segments';
            if (state.matchedLocation == '/work_logs') title = 'Work Logs';
            if (state.matchedLocation == '/schedule') title = 'My Schedule';
          } else if (userRole == UserRole.projectManager) {
            if (state.matchedLocation == '/') title = 'Command Center';
            if (state.matchedLocation == '/risks') title = 'Risk Dashboard';
            if (state.matchedLocation == '/create_segment') title = 'Create Segment';
          } else if (userRole == UserRole.manager) {
            if (state.matchedLocation == '/') title = 'Project Map';
            if (state.matchedLocation == '/bauleiter_map') title = 'Project Map';
            if (state.matchedLocation == '/crews') title = 'Field Crews';
            if (state.matchedLocation == '/inventory') title = 'Inventory';
          }

          return DashboardLayout(title: title, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final authState = ref.watch(authProvider);
              final userRole = authState.user?.role;
              if (userRole == UserRole.fieldExpert) return const ObreroMapScreen();
              if (userRole == UserRole.projectManager) return const ProjectsDashboardScreen();
              if (userRole == UserRole.manager) return const BauleiterMapScreen();
              return const Center(child: Text('Welcome to QuarkBau'));
            },
          ),
          GoRoute(
            path: '/obrero_map',
            builder: (context, state) => const ObreroMapScreen(),
          ),
          GoRoute(
            path: '/bauleiter_map',
            builder: (context, state) => const BauleiterMapScreen(),
          ),
          GoRoute(
            path: '/project_segments/:projectId',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return ProjectSegmentsScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/project_clusters/:projectId',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return ProjectClustersScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/project_clusters/:projectId/areas/:clusterId',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              final clusterId = state.pathParameters['clusterId']!;
              return ClusterAreaDashboardScreen(projectId: projectId, clusterId: clusterId);
            },
          ),
          GoRoute(
            path: '/segment_evidence/:segmentId',
            builder: (context, state) {
              final segmentId = state.pathParameters['segmentId']!;
              return SegmentEvidenceScreen(segmentId: segmentId);
            },
          ),
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: '/risks',
            builder: (context, state) => const RiskDashboardScreen(),
          ),
          GoRoute(
            path: '/crews',
            builder: (context, state) => const FieldCrewsScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/create_segment',
            builder: (context, state) => const CreateSegmentScreen(),
          ),
          GoRoute(
            path: '/create_segment/:projectId',
            builder: (context, state) => const CreateSegmentScreen(),
          ),
          GoRoute(
            path: '/work_logs',
            builder: (context, state) => const WorkLogsScreen(),
          ),
          GoRoute(
            path: '/create_log',
            builder: (context, state) => const CreateWorkLogScreen(),
          ),
          GoRoute(
            path: '/evidence_capture/:segmentId',
            builder: (context, state) {
              final segmentId = state.pathParameters['segmentId'] ?? 'unknown';
              return EvidenceCaptureScreen(segmentId: segmentId);
            },
          ),
          GoRoute(
            path: '/ar_companion',
            builder: (context, state) => const ARCompanionScreen(),
          ),
          GoRoute(
            path: '/offline_sync',
            builder: (context, state) => const OfflineSyncScreen(),
          ),
        ],
      ),
    ],
  );
});
