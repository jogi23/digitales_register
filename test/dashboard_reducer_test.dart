// Copyright (C) 2026 Johannes Feichter
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _hw1 = {
  "id": 1,
  "title": "Mathe Hausübung",
  "subtitle": "Seite 42",
  "label": null,
  "type": "gradeGroup",
  "homework": null,
  "checkable": false,
  "checked": false,
  "deleteable": false,
};

const _hw2 = {
  "id": 2,
  "title": "Deutsch Referat",
  "subtitle": "Kapitel 5",
  "label": null,
  "type": "gradeGroup",
  "homework": null,
  "checkable": false,
  "checked": false,
  "deleteable": false,
};

void main() {
  tearDown(() => mockNow = null);

  ProviderContainer makeContainer({DashboardState? initial}) {
    final container = ProviderContainer(
      overrides: initial != null
          ? [
              dashboardProvider.overrideWith(
                () => _TestDashboardNotifier(initial),
              ),
            ]
          : [],
    );
    pc.providerContainer = container;
    return container;
  }

  group('DashboardNotifier — _applyLoaded', () {
    test('new day is added to empty state', () {
      mockNow = UtcDateTime(2021, 1, 10);
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardProvider.notifier);

      notifier.testApplyLoaded(
        [
          {
            "date": "2021-01-10",
            "items": [_hw1],
          }
        ],
        false,
        false,
        false,
      );

      expect(container.read(dashboardProvider).allDays!.length, 1);
      expect(
        container.read(dashboardProvider).allDays!.first.homework.length,
        1,
      );
    });

    test('old past day not in response is removed', () {
      mockNow = UtcDateTime(2021, 1, 10);
      final initial = DashboardState(
        (b) => b.allDays.add(
          Day(
            (b) => b
              ..date = UtcDateTime(2021, 1, 5)
              ..lastRequested = UtcDateTime(2021)
              ..homework.add(Homework(
                (b) => b
                  ..id = 99
                  ..title = 'Old'
                  ..subtitle = ''
                  ..type = HomeworkType.gradeGroup
                  ..checked = false,
              )),
          ),
        ),
      );
      final container = makeContainer(initial: initial);
      addTearDown(container.dispose);
      final notifier = container.read(dashboardProvider.notifier);

      notifier.testApplyLoaded(
        [
          {
            "date": "2021-01-10",
            "items": [_hw1],
          },
        ],
        false,
        false,
        false,
      );

      final dates = container
          .read(dashboardProvider)
          .allDays!
          .map((d) => d.date.day)
          .toList();
      expect(dates, isNot(contains(5)));
      expect(dates, contains(10));
    });

    test('future day not in response is NOT removed', () {
      mockNow = UtcDateTime(2021, 1, 10);
      final initial = DashboardState(
        (b) => b.allDays.add(
          Day(
            (b) => b
              ..date = UtcDateTime(2021, 1, 5)
              ..lastRequested = UtcDateTime(2021)
              ..homework.add(Homework(
                (b) => b
                  ..id = 99
                  ..title = 'Future-ish'
                  ..subtitle = ''
                  ..type = HomeworkType.gradeGroup
                  ..checked = false,
              )),
          ),
        ),
      );
      final container = makeContainer(initial: initial);
      addTearDown(container.dispose);
      final notifier = container.read(dashboardProvider.notifier);

      notifier.testApplyLoaded(
        [
          {
            "date": "2021-01-10",
            "items": [_hw1],
          },
        ],
        true,
        false,
        false,
      );

      final dates = container
          .read(dashboardProvider)
          .allDays!
          .map((d) => d.date.day)
          .toList();
      expect(dates, contains(5));
    });

    test('deduplication removes duplicate items on same day', () {
      mockNow = UtcDateTime(2021, 1, 10);
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardProvider.notifier);

      notifier.testApplyLoaded(
        [
          {
            "date": "2021-01-10",
            "items": [_hw1, _hw1],
          }
        ],
        false,
        false,
        true,
      );

      expect(
        container.read(dashboardProvider).allDays!.first.homework.length,
        1,
      );
    });

    test('deduplication off: duplicate items are kept', () {
      mockNow = UtcDateTime(2021, 1, 10);
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardProvider.notifier);

      notifier.testApplyLoaded(
        [
          {
            "date": "2021-01-10",
            "items": [_hw1, _hw1],
          }
        ],
        false,
        false,
        false,
      );

      expect(
        container.read(dashboardProvider).allDays!.first.homework.length,
        2,
      );
    });

    test('multiple days are sorted by date', () {
      mockNow = UtcDateTime(2021, 1, 10);
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(dashboardProvider.notifier);

      notifier.testApplyLoaded(
        [
          {
            "date": "2021-01-12",
            "items": [_hw2],
          },
          {
            "date": "2021-01-10",
            "items": [_hw1],
          },
        ],
        false,
        false,
        false,
      );

      final days = container.read(dashboardProvider).allDays!;
      expect(days.length, 2);
      expect(days[0].date.day, 10);
      expect(days[1].date.day, 12);
    });
  });
}

/// Test-only notifier subclass that allows specifying initial state.
class _TestDashboardNotifier extends DashboardNotifier {
  final DashboardState _initial;
  _TestDashboardNotifier(this._initial);

  @override
  DashboardState build() => _initial;
}
