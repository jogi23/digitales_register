import 'package:built_redux/built_redux.dart';
import 'package:dr/actions/app_actions.dart';
import 'package:dr/actions/dashboard_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/reducer/reducer.dart';
import 'package:dr/util.dart';
import 'package:dr/utc_date_time.dart';
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

DaysLoadedPayload _loaded({
  required List<Object> days,
  bool future = false,
  bool deduplicateEntries = false,
  bool markNewOrChangedEntries = false,
}) {
  return DaysLoadedPayload((b) => b
    ..data = days
    ..future = future
    ..deduplicateEntries = deduplicateEntries
    ..markNewOrChangedEntries = markNewOrChangedEntries);
}

void main() {
  tearDown(() => mockNow = null);

  group('dashboard reducer — loaded action', () {
    test('new day is added to empty state', () async {
      mockNow = UtcDateTime(2021, 1, 10);
      final store = Store<AppState, AppStateBuilder, AppActions>(
        appReducerBuilder.build(),
        AppState(),
        AppActions(),
        middleware: middleware(includeErrorMiddleware: false),
      );

      await store.actions.dashboardActions.loaded(_loaded(
        days: [
          {"date": "2021-01-10", "items": [_hw1]}
        ],
      ));

      expect(store.state.dashboardState.allDays!.length, 1);
      expect(
        store.state.dashboardState.allDays!.first.homework.length,
        1,
      );
    });

    test('old past day not in response is removed', () async {
      mockNow = UtcDateTime(2021, 1, 10);
      final store = Store<AppState, AppStateBuilder, AppActions>(
        appReducerBuilder.build(),
        AppState(
          (b) => b.dashboardState.allDays.add(
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
        ),
        AppActions(),
        middleware: middleware(includeErrorMiddleware: false),
      );

      // response doesn't include Jan 5 — past day should be deleted
      await store.actions.dashboardActions.loaded(_loaded(
        days: [
          {"date": "2021-01-10", "items": [_hw1]},
        ],
        future: false,
      ));

      final dates = store.state.dashboardState.allDays!
          .map((d) => d.date.day)
          .toList();
      expect(dates, isNot(contains(5)));
      expect(dates, contains(10));
    });

    test('future day not in response is NOT removed', () async {
      mockNow = UtcDateTime(2021, 1, 10);
      final store = Store<AppState, AppStateBuilder, AppActions>(
        appReducerBuilder.build(),
        AppState(
          (b) => b.dashboardState.allDays.add(
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
        ),
        AppActions(),
        middleware: middleware(includeErrorMiddleware: false),
      );

      // future=true → past day kept even if not in response
      await store.actions.dashboardActions.loaded(_loaded(
        days: [
          {"date": "2021-01-10", "items": [_hw1]},
        ],
        future: true,
      ));

      final dates = store.state.dashboardState.allDays!
          .map((d) => d.date.day)
          .toList();
      expect(dates, contains(5));
    });

    test('deduplication removes duplicate items on same day', () async {
      mockNow = UtcDateTime(2021, 1, 10);
      final store = Store<AppState, AppStateBuilder, AppActions>(
        appReducerBuilder.build(),
        AppState(),
        AppActions(),
        middleware: middleware(includeErrorMiddleware: false),
      );

      // Same item appears twice
      await store.actions.dashboardActions.loaded(_loaded(
        days: [
          {
            "date": "2021-01-10",
            "items": [_hw1, _hw1], // duplicate
          }
        ],
        deduplicateEntries: true,
      ));

      expect(store.state.dashboardState.allDays!.first.homework.length, 1);
    });

    test('deduplication off: duplicate items are kept', () async {
      mockNow = UtcDateTime(2021, 1, 10);
      final store = Store<AppState, AppStateBuilder, AppActions>(
        appReducerBuilder.build(),
        AppState(),
        AppActions(),
        middleware: middleware(includeErrorMiddleware: false),
      );

      await store.actions.dashboardActions.loaded(_loaded(
        days: [
          {
            "date": "2021-01-10",
            "items": [_hw1, _hw1],
          }
        ],
        deduplicateEntries: false,
      ));

      expect(store.state.dashboardState.allDays!.first.homework.length, 2);
    });

    test('multiple days are sorted by date', () async {
      mockNow = UtcDateTime(2021, 1, 10);
      final store = Store<AppState, AppStateBuilder, AppActions>(
        appReducerBuilder.build(),
        AppState(),
        AppActions(),
        middleware: middleware(includeErrorMiddleware: false),
      );

      await store.actions.dashboardActions.loaded(_loaded(
        days: [
          {"date": "2021-01-12", "items": [_hw2]},
          {"date": "2021-01-10", "items": [_hw1]},
        ],
      ));

      final days = store.state.dashboardState.allDays!;
      expect(days.length, 2);
      expect(days[0].date.day, 10);
      expect(days[1].date.day, 12);
    });
  });
}
