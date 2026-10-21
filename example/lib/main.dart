// ignore_for_file: unused_element, prefer_const_constructors

/// Example Flutter app with DELIBERATE quality issues for testing.
///
/// Each issue is documented with the expected QA rule that should detect it.
/// This file serves as a test fixture for the analysis engine.
library;

import 'package:flutter/material.dart';

void main() {
  runApp(const QaTestApp());
}

class QaTestApp extends StatelessWidget {
  const QaTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QA Test App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const QaTestPage(),
    );
  }
}

class QaTestPage extends StatelessWidget {
  const QaTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QA Test Fixtures')),
      body: SingleChildScrollView(
        child: Column(
          // ISSUE: QA101 — Column in SingleChildScrollView without
          // mainAxisSize: MainAxisSize.min
          children: [
            // ISSUE: QA001 — IconButton without tooltip
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),

            // CLEAN: IconButton WITH tooltip — should NOT trigger QA001
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.home),
              tooltip: 'Go home',
            ),

            // ISSUE: QA002 — GestureDetector without Semantics
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 400, // ISSUE: QA104 — hardcoded large dimension
                height: 100,
                color: Colors.red,
                child: const Center(child: Text('Tap me')),
              ),
            ),

            // CLEAN: GestureDetector WITH Semantics — should NOT trigger QA002
            Semantics(
              label: 'Accessible tap area',
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 100,
                  height: 50,
                  color: Colors.green,
                ),
              ),
            ),

            // ISSUE: QA003 — Image.network without semanticLabel
            Image.network(
              'https://example.com/photo.jpg',
              width: 200,
              height: 200,
            ),

            // CLEAN: Image with semanticLabel — should NOT trigger QA003
            Image.network(
              'https://example.com/photo2.jpg',
              semanticLabel: 'A beautiful landscape',
              width: 200,
              height: 200,
            ),

            // CLEAN: Decorative image with excludeFromSemantics
            Image.network(
              'https://example.com/decorative.jpg',
              excludeFromSemantics: true,
              width: 100,
              height: 100,
            ),

            // ISSUE: QA004 — ExcludeSemantics hiding content
            ExcludeSemantics(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Hidden from accessibility'),
              ),
            ),

            // ISSUE: QA002 — InkWell without Semantics
            InkWell(
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tap this inkwell'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
