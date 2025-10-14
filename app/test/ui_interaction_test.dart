/// V8Ray UI交互测试
///
/// 测试用户界面的交互功能

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v8ray/main.dart';
import 'package:v8ray/presentation/widgets/animated_button.dart';
import 'package:v8ray/presentation/widgets/loading_overlay.dart';

void main() {
  group('应用启动测试', () {
    testWidgets('应用应该正常启动', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: V8RayApp()));

      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('应用应该显示简单模式页面', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: V8RayApp()));

      await tester.pumpAndSettle();

      // 应该能找到AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('动画按钮测试', () {
    testWidgets('AnimatedButton应该正确渲染', (WidgetTester tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(AnimatedButton), findsOneWidget);
    });

    testWidgets('AnimatedButton应该响应点击', (WidgetTester tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('AnimatedButton加载状态应该显示进度指示器', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedButton(text: 'Test Button', isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AnimatedButton禁用时不应该响应点击', (WidgetTester tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(text: 'Test Button', onPressed: null),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('AnimatedButton应该支持图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Test Button',
              icon: Icons.check,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('加载指示器测试', () {
    testWidgets('SkeletonLoader应该正确渲染', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonLoader(width: 200, height: 20)),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('ListSkeletonLoader应该渲染多个项目', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListSkeletonLoader(itemCount: 3, itemHeight: 60),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsNWidgets(3));
    });

    testWidgets('LoadingIndicator应该显示加载文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator(message: 'Loading...')),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('卡片组件测试', () {
    testWidgets('Card应该正确渲染', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Text('Test Card'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Test Card'), findsOneWidget);
    });
  });

  group('文本输入测试', () {
    testWidgets('TextField应该接受输入', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: TextField(controller: controller))),
      );

      await tester.enterText(find.byType(TextField), 'Test input');
      expect(controller.text, equals('Test input'));

      controller.dispose();
    });

    testWidgets('TextField应该显示提示文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(hintText: 'Enter text'),
            ),
          ),
        ),
      );

      expect(find.text('Enter text'), findsOneWidget);
    });
  });

  group('开关组件测试', () {
    testWidgets('Switch应该响应切换', (WidgetTester tester) async {
      var value = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Switch(
                  value: value,
                  onChanged: (newValue) {
                    setState(() => value = newValue);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(value, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(value, isTrue);
    });
  });

  group('列表组件测试', () {
    testWidgets('ListView应该渲染多个项目', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ListTile(title: Text('Item 1')),
                ListTile(title: Text('Item 2')),
                ListTile(title: Text('Item 3')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('ListTile应该响应点击', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: const Text('Test Item'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('对话框测试', () {
    testWidgets('AlertDialog应该正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Test Dialog'),
                            content: const Text('Dialog content'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('SnackBar测试', () {
    testWidgets('SnackBar应该正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test SnackBar')),
                    );
                  },
                  child: const Text('Show SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      expect(find.text('Test SnackBar'), findsOneWidget);
    });
  });

  group('图标测试', () {
    testWidgets('Icon应该正确渲染', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Icon(Icons.check))),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Icon应该支持颜色', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Icon(Icons.check, color: Colors.green)),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(Colors.green));
    });
  });
}
