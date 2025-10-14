/// V8Ray 应用测试
///
/// 基础的Widget测试

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:v8ray/main.dart';

void main() {
  testWidgets('V8Ray app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: V8RayApp()));

    // Pump a few frames to let the app initialize
    // Don't use pumpAndSettle because we have continuous animations (pulse animation)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The app should load without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
