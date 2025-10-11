// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v8ray_app/main.dart';

void main() {
  group('V8Ray App Widget Tests', () {
    testWidgets('App should display welcome message', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Verify that the app title is displayed
      expect(find.text('V8Ray'), findsOneWidget);
      
      // Verify that the welcome message is displayed
      expect(find.text('Welcome to V8Ray!'), findsOneWidget);
      
      // Verify that the subtitle is displayed
      expect(find.text('Cross-platform Xray Core client'), findsOneWidget);
    });

    testWidgets('App should have correct theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Find the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify theme configuration
      expect(materialApp.theme, isNotNull);
      expect(materialApp.theme!.useMaterial3, isTrue);
      expect(materialApp.theme!.colorScheme.primary, Colors.blue);
    });

    testWidgets('HomePage should be displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Verify that HomePage is displayed
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('HomePage should have AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Verify that AppBar is present
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verify AppBar title
      expect(find.descendant(
        of: find.byType(AppBar),
        matching: find.text('V8Ray'),
      ), findsOneWidget);
    });

    testWidgets('HomePage should have centered content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Verify that content is centered
      expect(find.byType(Center), findsOneWidget);
      
      // Verify that Column is used for layout
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('App should handle navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Verify that MaterialApp has proper navigation setup
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.home, isA<HomePage>());
    });
  });

  group('HomePage Widget Tests', () {
    testWidgets('HomePage should display all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Verify main title
      expect(find.text('Welcome to V8Ray!'), findsOneWidget);
      
      // Verify subtitle
      expect(find.text('Cross-platform Xray Core client'), findsOneWidget);
      
      // Verify that text is styled correctly
      final titleFinder = find.text('Welcome to V8Ray!');
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontSize, 24);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('HomePage should have proper layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Verify layout structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('HomePage should handle different screen sizes', (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Mobile
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      expect(find.text('Welcome to V8Ray!'), findsOneWidget);

      // Test with tablet size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pump();

      expect(find.text('Welcome to V8Ray!'), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Provider Tests', () {
    testWidgets('ProviderScope should be properly configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Text('Test'),
            ),
          ),
        ),
      );

      // Verify that ProviderScope is working
      expect(find.byType(ProviderScope), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('App should work without providers initially', (WidgetTester tester) async {
      // Test that the app can start without any complex providers
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('App should have proper semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Verify that important elements have semantics
      expect(find.bySemanticsLabel('V8Ray'), findsOneWidget);
    });

    testWidgets('App should support screen readers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Verify that text is accessible
      final semantics = tester.getSemantics(find.text('Welcome to V8Ray!'));
      expect(semantics.label, contains('Welcome to V8Ray!'));
    });
  });

  group('Performance Tests', () {
    testWidgets('App should build quickly', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );
      
      stopwatch.stop();
      
      // App should build in less than 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('App should handle multiple rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: V8RayApp(),
        ),
      );

      // Trigger multiple rebuilds
      for (int i = 0; i < 10; i++) {
        await tester.pump();
      }

      // Should not throw any errors
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome to V8Ray!'), findsOneWidget);
    });
  });
}
