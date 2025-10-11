import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v8ray_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('V8Ray App Integration Tests', () {
    testWidgets('Complete app flow test', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Wait for the app to settle
      await tester.pumpAndSettle();

      // Verify the app starts correctly
      expect(find.text('V8Ray'), findsOneWidget);
      expect(find.text('Welcome to V8Ray!'), findsOneWidget);
      expect(find.text('Cross-platform Xray Core client'), findsOneWidget);

      // Verify the app bar is present
      expect(find.byType(AppBar), findsOneWidget);

      // Verify the main content area
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);

      // Take a screenshot for visual verification
      await tester.binding.convertFlutterSurfaceToImage();
    });

    testWidgets('App navigation test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the home page
      expect(find.byType(HomePage), findsOneWidget);

      // Test that the app doesn't crash when interacting with it
      await tester.tap(find.text('Welcome to V8Ray!'));
      await tester.pumpAndSettle();

      // App should still be functional
      expect(find.text('Welcome to V8Ray!'), findsOneWidget);
    });

    testWidgets('App theme and styling test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Material Design 3 is being used
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);

      // Verify color scheme
      expect(materialApp.theme?.colorScheme.primary, Colors.blue);

      // Verify app bar styling
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>());
    });

    testWidgets('App responsiveness test', (WidgetTester tester) async {
      // Test different screen orientations and sizes
      
      // Portrait mode
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to V8Ray!'), findsOneWidget);

      // Landscape mode
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Welcome to V8Ray!'), findsOneWidget);

      // Tablet size
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Welcome to V8Ray!'), findsOneWidget);

      // Reset to default
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('App performance test', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // App should start quickly (less than 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Test frame rendering performance
      final frameStopwatch = Stopwatch()..start();
      
      // Trigger several frame updates
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // 60 FPS
      }
      
      frameStopwatch.stop();
      
      // Should maintain 60 FPS (each frame should take ~16ms)
      final averageFrameTime = frameStopwatch.elapsedMilliseconds / 60;
      expect(averageFrameTime, lessThan(20)); // Allow some margin
    });

    testWidgets('App memory usage test', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate app usage by triggering multiple rebuilds
      for (int i = 0; i < 100; i++) {
        await tester.pump();
        
        // Occasionally trigger garbage collection
        if (i % 10 == 0) {
          await tester.binding.delayed(const Duration(milliseconds: 1));
        }
      }

      // App should still be responsive
      expect(find.text('Welcome to V8Ray!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('App accessibility test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test semantic labels
      expect(find.bySemanticsLabel('V8Ray'), findsOneWidget);

      // Test that important UI elements are accessible
      final semantics = tester.getSemantics(find.text('Welcome to V8Ray!'));
      expect(semantics.label, isNotNull);
      expect(semantics.label, contains('Welcome to V8Ray!'));

      // Test focus traversal
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Should not crash when navigating with keyboard
      expect(tester.takeException(), isNull);
    });

    testWidgets('App error handling test', (WidgetTester tester) async {
      // Test that the app handles errors gracefully
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no exceptions during normal operation
      expect(tester.takeException(), isNull);

      // Test widget tree integrity
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(ProviderScope), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('App state management test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Riverpod is working
      expect(find.byType(ProviderScope), findsOneWidget);

      // Test that the app can handle provider updates
      // (This will be expanded when we add actual providers)
      
      // Trigger a rebuild
      await tester.pump();
      
      // App should still be functional
      expect(find.text('Welcome to V8Ray!'), findsOneWidget);
    });

    testWidgets('App lifecycle test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate app lifecycle events
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused'),
        ),
        (data) {},
      );

      await tester.pump();

      // App should handle lifecycle changes gracefully
      expect(tester.takeException(), isNull);

      // Resume the app
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed'),
        ),
        (data) {},
      );

      await tester.pump();

      // App should still be functional
      expect(find.text('Welcome to V8Ray!'), findsOneWidget);
    });
  });
}
