// Copyright (C) 2026 Johannes Feichter
import 'package:dr/app_state.dart';
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

  group('SettingsNotifier — star colour', () {
    test('setStarColor stores the chosen palette id', () {
      final c = _makeContainer();
      expect(c.read(settingsProvider).starColor, accentStarColorId);
      c.read(settingsProvider.notifier).setStarColor('amber');
      expect(c.read(settingsProvider).starColor, 'amber');
    });

    test('survives a save/restore round trip', () {
      final saved = SettingsState(starColor: 'teal');
      expect(
        SettingsState.fromJson(saved.toJson()).starColor,
        'teal',
      );
    });

    test('settings written before the setting existed keep the accent colour',
        () {
      final old = SettingsState().toJson()..remove('starColor');
      expect(SettingsState.fromJson(old).starColor, accentStarColorId);
    });
  });
}
