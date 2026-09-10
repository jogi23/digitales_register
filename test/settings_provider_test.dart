// Copyright (C) 2026 Johannes Feichter
import 'package:dr/app_state.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer _makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('app-wide vs. per-account settings', () {
    test('an app-wide setting is still there after a restart', () async {
      final before = _makeContainer();
      before.read(settingsProvider.notifier).setStarColor('amber');
      await pumpEventQueue();

      final after = _makeContainer();
      await after.read(settingsProvider.notifier).loadGlobal();
      expect(after.read(settingsProvider).starColor, 'amber');
    });

    test('a setting that belongs to the account is not stored app-wide',
        () async {
      // "Noten nach Art gruppieren" sits on the grades screen, not in the
      // four sections that are shared.
      final before = _makeContainer();
      before.read(settingsProvider.notifier).setGradesTypeSorted(true);
      await pumpEventQueue();

      final after = _makeContainer();
      await after.read(settingsProvider.notifier).loadGlobal();
      expect(after.read(settingsProvider).typeSorted, isFalse);
    });

    test('the classbook subject filter belongs to the account', () async {
      // Welche Fächer es gibt, hängt am Konto - die Auswahl eines Kindes
      // sagt nichts über die eines anderen. Die Ansichtsform dagegen ist
      // Geschmack und gilt app-weit.
      final before = _makeContainer();
      before
          .read(settingsProvider.notifier)
          .setClassbookSubjects(['Deutsch', 'Musik']);
      before
          .read(settingsProvider.notifier)
          .setClassbookViewMode(ClassbookViewMode.bySubject);
      await pumpEventQueue();

      final after = _makeContainer();
      await after.read(settingsProvider.notifier).loadGlobal();
      expect(after.read(settingsProvider).classbookSubjects, isEmpty);
      expect(after.read(settingsProvider).classbookViewMode,
          ClassbookViewMode.bySubject);
    });

    test('logging into an account keeps the app-wide settings', () async {
      final c = _makeContainer();
      c.read(settingsProvider.notifier).setStarColor('teal');
      await pumpEventQueue();

      // The account's stored state still carries an older app-wide value.
      c.read(settingsProvider.notifier).load(
            SettingsState(starColor: 'red', typeSorted: true),
          );

      expect(c.read(settingsProvider).starColor, 'teal');
      expect(c.read(settingsProvider).typeSorted, isTrue);
    });

    test('the first start after the split adopts what the account had',
        () async {
      // Otherwise everyone would find their settings back at the defaults.
      final c = _makeContainer();
      await c.read(settingsProvider.notifier).loadGlobal();
      c.read(settingsProvider.notifier).load(
            SettingsState(
              starColor: 'red',
              dashboardViewMode: DashboardViewMode.week,
            ),
          );

      expect(c.read(settingsProvider).starColor, 'red');
      expect(c.read(settingsProvider).dashboardViewMode,
          DashboardViewMode.week);
    });
  });

  group('switching accounts', () {
    test('resets the account settings but keeps the app-wide ones', () async {
      // An account with nothing stored yet used to inherit everything from
      // the account one came from.
      final c = _makeContainer();
      final notifier = c.read(settingsProvider.notifier);
      notifier
        ..setStarColor('amber')
        ..setDashboardViewMode(DashboardViewMode.week)
        ..setGradesTypeSorted(true)
        ..setShowCalendarNicksBar(false)
        ..setSaveNoPass(true);
      await pumpEventQueue();

      notifier.resetForAccount();

      final s = c.read(settingsProvider);
      expect(s.starColor, 'amber');
      expect(s.dashboardViewMode, DashboardViewMode.week);
      expect(s.typeSorted, isFalse);
      expect(s.showCalendarNicksBar, isTrue);
      // Password saving is about this device, and the middleware carries the
      // running value over anyway.
      expect(s.noPasswordSaving, isTrue);
    });
  });

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
