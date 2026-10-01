import 'package:flutter_test/flutter_test.dart';
import 'package:sahulat_ghar_tak/models/app_config.dart';
import 'package:sahulat_ghar_tak/utils/version_compare.dart';

AppConfig _config({String min = '1.0.0', String latest = '1.0.0', bool force = false}) => AppConfig(
      minimumRequiredVersion: min,
      latestVersion: latest,
      forceUpdate: force,
      storeUrl: 'https://example.com',
      updateMessage: '',
    );

void main() {
  group('compareVersions', () {
    test('compares numerically per segment', () {
      expect(compareVersions('1.0.10', '1.0.9'), greaterThan(0));
      expect(compareVersions('1.0.9', '1.0.10'), lessThan(0));
    });

    test('treats missing segments as zero and ignores build suffix', () {
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1.0.4+10', '1.0.4'), 0);
      expect(compareVersions('2', '1.9.9'), greaterThan(0));
    });
  });

  group('evaluateUpdate', () {
    test('none when up to date', () {
      expect(evaluateUpdate('1.0.4', _config(min: '1.0.0', latest: '1.0.4')), AppUpdateKind.none);
    });

    test('required when below minimum', () {
      expect(evaluateUpdate('1.0.2', _config(min: '1.0.3', latest: '1.0.4')), AppUpdateKind.required);
    });

    test('required when forced and below latest', () {
      expect(evaluateUpdate('1.0.3', _config(latest: '1.0.4', force: true)), AppUpdateKind.required);
    });

    test('optional when only below latest', () {
      expect(evaluateUpdate('1.0.3', _config(latest: '1.0.4')), AppUpdateKind.optional);
    });
  });
}
