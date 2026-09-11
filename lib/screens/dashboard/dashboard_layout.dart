import 'package:flutter/material.dart';
import '../../widgets/custom_drawer.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const DashboardLayout({Key? key, required this.child, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: CustomDrawer(),
      body: child,
    );
  }
}
