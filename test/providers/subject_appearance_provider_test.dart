// Copyright (C) 2026 Johannes Feichter
import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/providers/all_subjects_provider.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/api_fixtures.dart';

ProviderContainer _makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('SubjectAppearanceNotifier — ensureThemesFor', () {
    test('new subject receives a SubjectTheme with default thick', () async {
      final c = _makeContainer();
      await c.read(subjectAppearanceProvider.notifier).ensureThemesFor(['Mathe']);
      final themes = c.read(subjectAppearanceProvider).themes;
      expect(themes.containsKey('mathe'), true);
      expect(themes['mathe']!.thick, 2);
    });

    test('multiple new subjects each get a theme', () async {
      final c = _makeContainer();
      await c
          .read(subjectAppearanceProvider.notifier)
          .ensureThemesFor(['Mathe', 'Deutsch', 'Englisch']);
      final themes = c.read(subjectAppearanceProvider).themes;
      expect(themes.containsKey('mathe'), true);
      expect(themes.containsKey('deutsch'), true);
      expect(themes.containsKey('englisch'), true);
    });

    test('two new subjects get different colors', () async {
      final c = _makeContainer();
      await c
          .read(subjectAppearanceProvider.notifier)
          .ensureThemesFor(['Mathe', 'Deutsch']);
      final themes = c.read(subjectAppearanceProvider).themes;
      expect(themes['mathe']!.color, isNot(equals(themes['deutsch']!.color)));
    });

    test('18 subjects all get unique colors (exhausts deterministic palette)',
        () async {
      final c = _makeContainer();
      final subjects = List.generate(18, (i) => 'Subject$i');
      await c.read(subjectAppearanceProvider.notifier).ensureThemesFor(subjects);
      final themes = c.read(subjectAppearanceProvider).themes;
      final colors =
          subjects.map((s) => themes[normalizeSubject(s)]!.color).toSet();
      expect(colors.length, 18);
    });

    test('existing subject is not overwritten', () async {
      final c = _makeContainer();
      const customColor = 0xFF123456;
      await c
          .read(subjectAppearanceProvider.notifier)
          .setTheme('Mathe', SubjectTheme(thick: 5, color: customColor));
      await c
          .read(subjectAppearanceProvider.notifier)
          .ensureThemesFor(['Mathe', 'Deutsch']);
      final themes = c.read(subjectAppearanceProvider).themes;
      expect(themes['mathe']!.color, customColor);
      expect(themes['mathe']!.thick, 5);
    });

    test('empty list does nothing', () async {
      final c = _makeContainer();
      final before = c.read(subjectAppearanceProvider);
      await c.read(subjectAppearanceProvider.notifier).ensureThemesFor([]);
      expect(identical(c.read(subjectAppearanceProvider), before), true);
    });

    test('same subject in different casing across accounts shares one entry',
        () async {
      final c = _makeContainer();
      await c
          .read(subjectAppearanceProvider.notifier)
          .ensureThemesFor(['Mathematik']);
      final theme = c.read(subjectAppearanceProvider).themeFor('Mathematik');
      await c
          .read(subjectAppearanceProvider.notifier)
          .ensureThemesFor(['mathematik']);
      expect(c.read(subjectAppearanceProvider).themes.length, 1);
      expect(c.read(subjectAppearanceProvider).themeFor('MATHEMATIK'), theme);
    });
  });

  group('SubjectAppearanceNotifier — nicknames', () {
    test('setNick and nickFor round-trip case-insensitively', () async {
      final c = _makeContainer();
      await c
          .read(subjectAppearanceProvider.notifier)
          .setNick('Mathematik', 'Mat');
      expect(c.read(subjectAppearanceProvider).nickFor('mathematik'), 'Mat');
      expect(c.read(subjectAppearanceProvider).nickFor('MATHEMATIK'), 'Mat');
    });

    test('removeNick clears the nickname', () async {
      final c = _makeContainer();
      await c.read(subjectAppearanceProvider.notifier).setNick('Mathe', 'Mat');
      await c.read(subjectAppearanceProvider.notifier).removeNick('Mathe');
      expect(c.read(subjectAppearanceProvider).nickFor('Mathe'), null);
    });

    test('themeFor falls back to a default theme for unknown subjects', () {
      final c = _makeContainer();
      final theme = c.read(subjectAppearanceProvider).themeFor('Unbekannt');
      expect(theme, const SubjectTheme());
    });
  });

  group('keeping up with the subjects the app learns about', () {
    setUpAll(loadFixtures);

    /// One week of the timetable, as the register sends it.
    CalendarState weekOfTimetable(ProviderContainer c) {
      final raw = fixtureFor(
        'api/calendar/student',
        params: {'startDate': '2026-05-11'},
      ) as Map<String, dynamic>;
      return CalendarState(
        (b) => b..days = MapBuilder(c.read(calendarProvider.notifier).parseLoaded(raw)),
      );
    }

    test('a subject only the timetable knows still gets a colour', () async {
      // The timetable arrives long after the login, which used to be where
      // colours were handed out — those lessons stayed grey (#259).
      final c = _makeContainer();
      keepSubjectThemesUpToDate(c);
      expect(c.read(subjectAppearanceProvider).themes, isEmpty);

      c.read(calendarProvider.notifier).restore(weekOfTimetable(c));
      c.read(allSubjectsProvider);
      await pumpEventQueue();

      final themes = c.read(subjectAppearanceProvider).themes;
      expect(themes.containsKey(normalizeSubject('Mathematik')), isTrue);
      expect(themes.containsKey(normalizeSubject('Religion')), isTrue);
    });

    test('every lesson of the week has one, not just the first', () async {
      final c = _makeContainer();
      keepSubjectThemesUpToDate(c);
      final week = weekOfTimetable(c);
      c.read(calendarProvider.notifier).restore(week);
      c.read(allSubjectsProvider);
      await pumpEventQueue();

      final themes = c.read(subjectAppearanceProvider).themes;
      for (final day in week.days.values) {
        for (final hour in day.hours) {
          expect(
            themes.containsKey(normalizeSubject(hour.subject)),
            isTrue,
            reason: hour.subject,
          );
        }
      }
    });
  });
}
