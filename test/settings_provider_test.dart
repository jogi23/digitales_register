// Copyright (C) 2026 Johannes Feichter
import 'package:dr/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('SettingsNotifier — load', () {
    test('load restores settings and clears the grades scroll flag', () {
      final c = _makeContainer();
      c.read(settingsProvider.notifier).scrollToGradesSection();
      final saved = c.read(settingsProvider).copyWith(noPasswordSaving: true);
      c.read(settingsProvider.notifier).load(saved);
      final s = c.read(settingsProvider);
      expect(s.noPasswordSaving, true);
      expect(s.scrollToGrades, false);
    });
  });
}
