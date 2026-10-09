import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_drawer.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_message.dart';
import 'notification_detail_screen.dart';

class DashboardLayout extends ConsumerWidget {
  final Widget child;
  final String title;

  const DashboardLayout({Key? key, required this.child, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);

    // Listen for new notifications to show a Top Snackbar
    ref.listen<NotificationState>(notificationProvider, (previous, next) {
      if (previous != null && next.notifications.length > previous.notifications.length) {
        final newMsg = next.notifications.first;
        _showTopSnackbar(context, newMsg);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  ref.read(notificationProvider.notifier).markAllAsRead();
                  _showNotificationList(context, ref);
                },
              ),
              if (notifState.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notifState.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: CustomDrawer(),
      body: child,
    );
  }

  void _showNotificationList(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16171A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, watchRef, child) {
            final notifs = watchRef.watch(notificationProvider).notifications;
            return Container(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 20),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('COMMAND CENTER', style: TextStyle(fontSize: 16, fontFamily: 'monospace', letterSpacing: 2.0, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('REAL-TIME LOGS', style: TextStyle(fontSize: 10, fontFamily: 'monospace', letterSpacing: 1.5, color: Colors.white54)),
                  const SizedBox(height: 24),
                  if (notifs.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('NO ACTIVITY DETECTED', style: TextStyle(color: Colors.white30, fontFamily: 'monospace', letterSpacing: 1.5)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: notifs.length,
                        itemBuilder: (ctx, index) {
                          final n = notifs[index];
                          String badgeText = "UPDATE";
                          Color badgeColor = Colors.blueAccent;
                          if (n.title.contains('Completada')) { badgeText = "COMPLETED"; badgeColor = const Color(0xFF34d399); }
                          else if (n.title.contains('Bloqueado')) { badgeText = "BLOCKED"; badgeColor = const Color(0xFFef4444); }
                          else if (n.title.contains('IN_PROGRESS')) { badgeText = "IN PROGRESS"; badgeColor = const Color(0xFF60a5fa); }
                          else if (n.title.contains('Planificado')) { badgeText = "PLAN"; badgeColor = const Color(0xFFa78bfa); }
                          else if (n.title.contains('HOLD')) { badgeText = "HOLD"; badgeColor = const Color(0xFFfbbf24); }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16171A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1.5, fontFamily: 'monospace'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: badgeColor.withOpacity(0.5)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  n.body,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                ),
                                const SizedBox(height: 20),
                                Divider(color: Colors.white.withOpacity(0.05), thickness: 1),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('TIME :', style: TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 1.5, fontFamily: 'monospace')),
                                        const SizedBox(height: 4),
                                        Text('${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')} - ${n.timestamp.day.toString().padLeft(2, '0')}/${n.timestamp.month.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace', letterSpacing: 1.0)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationDetailScreen(notification: n)));
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          ),
                                          child: const Text('VIEW DETAILS', style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.5, fontFamily: 'monospace')),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTopSnackbar(BuildContext context, NotificationMessage message) {
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight;

    String badgeText = "UPDATE";
    Color badgeColor = Colors.blueAccent;
    if (message.title.contains('Completada')) { badgeText = "COMPLETED"; badgeColor = const Color(0xFF34d399); }
    else if (message.title.contains('Bloqueado')) { badgeText = "BLOCKED"; badgeColor = const Color(0xFFef4444); }
    else if (message.title.contains('IN_PROGRESS')) { badgeText = "IN PROGRESS"; badgeColor = const Color(0xFF60a5fa); }
    else if (message.title.contains('Planificado')) { badgeText = "PLAN"; badgeColor = const Color(0xFFa78bfa); }
    else if (message.title.contains('HOLD')) { badgeText = "HOLD"; badgeColor = const Color(0xFFfbbf24); }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    message.title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, fontFamily: 'monospace', color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: badgeColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(message.body, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - (topPadding + appBarHeight + 150), 
            left: 16, 
            right: 16
        ),
        backgroundColor: const Color(0xFF16171A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05))
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.blueAccent,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationDetailScreen(notification: message)));
          },
        ),
      ),
    );
  }
}
