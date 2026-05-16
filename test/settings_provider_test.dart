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
  group('SettingsNotifier — updateSubjectThemes', () {
    test('new subject receives a SubjectTheme with default thick', () {
      final c = _makeContainer();
      c.read(settingsProvider.notifier).updateSubjectThemes(['Mathe']);
      final themes = c.read(settingsProvider).subjectThemes;
      expect(themes.containsKey('Mathe'), true);
      expect(themes['Mathe']!.thick, 2);
    });

    test('multiple new subjects each get a theme', () {
      final c = _makeContainer();
      c.read(settingsProvider.notifier).updateSubjectThemes(['Mathe', 'Deutsch', 'Englisch']);
      final themes = c.read(settingsProvider).subjectThemes;
      expect(themes.containsKey('Mathe'), true);
      expect(themes.containsKey('Deutsch'), true);
      expect(themes.containsKey('Englisch'), true);
    });

    test('two new subjects get different colors', () {
      final c = _makeContainer();
      c.read(settingsProvider.notifier).updateSubjectThemes(['Mathe', 'Deutsch']);
      final themes = c.read(settingsProvider).subjectThemes;
      expect(themes['Mathe']!.color, isNot(equals(themes['Deutsch']!.color)));
    });

    test('18 subjects all get unique colors (exhausts deterministic palette)', () {
      final c = _makeContainer();
      final subjects = List.generate(18, (i) => 'Subject$i');
      c.read(settingsProvider.notifier).updateSubjectThemes(subjects);
      final themes = c.read(settingsProvider).subjectThemes;
      final colors = subjects.map((s) => themes[s]!.color).toSet();
      expect(colors.length, 18);
    });

    test('existing subject is not overwritten', () {
      final c = _makeContainer();
      const customColor = 0xFF123456;
      c.read(settingsProvider.notifier).setSubjectTheme(
        MapEntry('Mathe', SubjectTheme((t) => t..thick = 5..color = customColor)),
      );
      c.read(settingsProvider.notifier).updateSubjectThemes(['Mathe', 'Deutsch']);
      final themes = c.read(settingsProvider).subjectThemes;
      expect(themes['Mathe']!.color, customColor);
      expect(themes['Mathe']!.thick, 5);
    });

    test('no state change when all subjects already exist', () {
      final c = _makeContainer();
      c.read(settingsProvider.notifier).updateSubjectThemes(['Mathe']);
      final before = c.read(settingsProvider);
      c.read(settingsProvider.notifier).updateSubjectThemes(['Mathe']);
      expect(identical(c.read(settingsProvider), before), true);
    });

    test('empty list does nothing', () {
      final c = _makeContainer();
      final before = c.read(settingsProvider);
      c.read(settingsProvider.notifier).updateSubjectThemes([]);
      expect(identical(c.read(settingsProvider), before), true);
    });
  });

  group('SettingsNotifier — setSaveNoData', () {
    test('setSaveNoData updates state and calls onSaveState', () {
      final c = _makeContainer();
      int saveStateCalls = 0;
      c.read(settingsProvider.notifier).onSaveState = () => saveStateCalls++;
      c.read(settingsProvider.notifier).setSaveNoData(true);
      expect(c.read(settingsProvider).noDataSaving, true);
      expect(saveStateCalls, 1);
    });

    test('setSaveNoData without onSaveState wired does not throw', () {
      final c = _makeContainer();
      expect(
        () => c.read(settingsProvider.notifier).setSaveNoData(true),
        returnsNormally,
      );
    });
  });

  group('SettingsNotifier — load', () {
    test('load restores settings and clears scroll flags', () {
      final c = _makeContainer();
      c.read(settingsProvider.notifier).scrollToGradesSection();
      final saved = c.read(settingsProvider).rebuild(
        (b) => b..noPasswordSaving = true,
      );
      c.read(settingsProvider.notifier).load(saved);
      final s = c.read(settingsProvider);
      expect(s.noPasswordSaving, true);
      expect(s.scrollToGrades, false);
      expect(s.scrollToSubjectNicks, false);
    });
  });
}
