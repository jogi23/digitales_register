// Copyright (C) 2026 Johannes Feichter
import 'package:built_redux/built_redux.dart';
import 'package:dr/actions/app_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/reducer/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

Store<AppState, AppStateBuilder, AppActions> _makeStore() {
  return Store<AppState, AppStateBuilder, AppActions>(
    appReducerBuilder.build(),
    AppState(),
    AppActions(),
    middleware: middleware(includeErrorMiddleware: false),
  );
}

// Minimal absence group JSON with one full-hour absence (minutes==50).
const _oneAbsencePayload = {
  "statistics": {
    "counter": 1,
    "counterForSchool": 0,
    "percentage": "",
    "justified": 2,
    "notJustified": 1,
    "delayed": 0,
  },
  "absences": [
    {
      "group": [
        {
          "id": 1,
          "minutes": 50,
          "minutes_begin": 0,
          "minutes_end": 0,
          "justified": 2, // → AbsenceJustified.justified
          "note": null,
          "date": "2021-02-02",
          "hour": 1,
          "reason": "Krank",
          "reason_signature": null,
          "reason_timestamp": null,
          "reason_user": 1,
          "selfdecl_id": null,
          "selfdecl_input": null,
        }
      ],
      "date": "2021-02-02",
      "note": null,
      "reason": "Krank",
      "reason_signature": null,
      "reason_timestamp": null,
      "reason_user": 1,
      "justified": 2,
      "selfdecl_id": null,
      "selfdecl_input": null,
    }
  ],
  "futureAbsences": [],
};

// Absence group with late arrival (minutes!=50).
const _lateArrivalPayload = {
  "statistics": {
    "counter": 0,
    "counterForSchool": 0,
    "percentage": "",
    "justified": 0,
    "notJustified": 0,
    "delayed": 1,
  },
  "absences": [
    {
      "group": [
        {
          "id": 2,
          "minutes": 20, // not 50 → counts as minutes late
          "minutes_begin": 15,
          "minutes_end": 5,
          "justified": 1, // → notYetJustified
          "note": null,
          "date": "2021-02-03",
          "hour": 2,
          "reason": null,
          "reason_signature": null,
          "reason_timestamp": null,
          "reason_user": null,
          "selfdecl_id": null,
          "selfdecl_input": null,
        }
      ],
      "date": "2021-02-03",
      "note": null,
      "reason": null,
      "reason_signature": null,
      "reason_timestamp": null,
      "reason_user": null,
      "justified": 1,
      "selfdecl_id": null,
      "selfdecl_input": null,
    }
  ],
  "futureAbsences": [],
};

void main() {
  group('absences reducer — loaded action', () {
    test('parses absence group and statistic', () async {
      final store = _makeStore();
      await store.actions.absencesActions.loaded(_oneAbsencePayload);

      final state = store.state.absencesState;
      expect(state.absences.length, 1);
      expect(state.statistic!.justified, 2);
      expect(state.statistic!.notJustified, 1);
      expect(state.statistic!.delayed, 0);
    });

    test('counts hours correctly (minutes==50 → 1 hour)', () async {
      final store = _makeStore();
      await store.actions.absencesActions.loaded(_oneAbsencePayload);

      final group = store.state.absencesState.absences.first;
      expect(group.hours, 1);
      expect(group.minutes, 0); // 50-minute absence → full hour, not minutes
    });

    test('justified field parsed correctly', () async {
      final store = _makeStore();
      await store.actions.absencesActions.loaded(_oneAbsencePayload);

      final group = store.state.absencesState.absences.first;
      expect(group.justified, AbsenceJustified.justified);
    });

    test('late arrival counted as minutes, not hours', () async {
      final store = _makeStore();
      await store.actions.absencesActions.loaded(_lateArrivalPayload);

      final group = store.state.absencesState.absences.first;
      expect(group.hours, 0);
      expect(group.minutes, 20); // minutesCameTooLate + minutesLeftTooEarly
    });

    test('notYetJustified parsed from int 1', () async {
      final store = _makeStore();
      await store.actions.absencesActions.loaded(_lateArrivalPayload);

      final group = store.state.absencesState.absences.first;
      expect(group.justified, AbsenceJustified.notYetJustified);
    });

    test('empty absences list', () async {
      final store = _makeStore();
      await store.actions.absencesActions.loaded(const {
        "statistics": {
          "counter": 0,
          "counterForSchool": 0,
          "percentage": "",
          "justified": 0,
          "notJustified": 0,
          "delayed": 0,
        },
        "absences": [],
        "futureAbsences": [],
      });

      expect(store.state.absencesState.absences, isEmpty);
    });
  });
}
