import 'package:flutter_test/flutter_test.dart';
import 'package:v8ray/core/constants/app_constants.dart';

void main() {
  group('Version Management Tests', () {
    test('AppInfo version should be valid', () {
      expect(AppInfo.version, isNotEmpty);
      expect(AppInfo.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('AppInfo version should be 0.2.0', () {
      expect(AppInfo.version, '0.2.0');
    });

    test('AppInfo buildNumber should be valid', () {
      expect(AppInfo.buildNumber, greaterThan(0));
    });

    test('AppInfo buildNumber should be 2', () {
      expect(AppInfo.buildNumber, 2);
    });

    test('AppInfo userAgent should be valid', () {
      expect(AppInfo.userAgent, isNotEmpty);
      expect(AppInfo.userAgent, contains('V8Ray'));
      expect(AppInfo.userAgent, contains(AppInfo.version));
    });

    test('AppInfo userAgent should match format', () {
      expect(AppInfo.userAgent, 'V8Ray/0.2.0');
    });

    test('AppInfo should have all required fields', () {
      expect(AppInfo.appName, 'V8Ray');
      expect(AppInfo.description, isNotEmpty);
      expect(AppInfo.developer, 'V8Ray Team');
      expect(AppInfo.homepage, 'https://github.com/v8ray/v8ray');
      expect(AppInfo.issuesUrl, 'https://github.com/v8ray/v8ray/issues');
      expect(AppInfo.githubApiUrl, isNotEmpty);
      expect(AppInfo.githubReleasesUrl, isNotEmpty);
    });
  });
}
