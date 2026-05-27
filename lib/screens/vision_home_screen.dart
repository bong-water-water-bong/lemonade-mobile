import 'package:flutter/material.dart';

import 'capture_screen.dart';
import 'deduce_screen.dart';

class VisionHomeScreen extends StatelessWidget {
  const VisionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vision'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.search), text: 'Lookup'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Onboard'),
          ]),
        ),
        body: TabBarView(
          children: [
            const DeduceScreen(),
            _OnboardTab(),
          ],
        ),
      ),
    );
  }
}

class _OnboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      const Text('Scan a new product to add it\nto the cashier database',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 24),
      FilledButton.icon(
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan New Product'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CaptureScreen()),
        ),
      ),
    ]),
  );
}
