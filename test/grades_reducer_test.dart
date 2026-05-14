// Copyright (C) 2026 Johannes Feichter
import 'package:built_redux/built_redux.dart';
import 'package:dr/actions/app_actions.dart';
import 'package:dr/actions/grades_actions.dart';
import 'package:dr/app_state.dart';
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

SubjectsLoadedPayload _payload(Object data, {Semester? semester}) {
  return SubjectsLoadedPayload((b) => b
    ..semester = (semester ?? Semester.first).toBuilder()
    ..data = data);
}

const _mathSubject = {
  "subjects": [
    {
      "subject": {"id": 1, "name": "Mathematik"},
      "grades": [
        {
          "grade": "7.50",
          "weight": 100,
          "date": "2021-01-04",
          "cancelled": 0,
          "type": "Schularbeit",
        }
      ],
    }
  ]
};

const _germanSubject = {
  "subjects": [
    {
      "subject": {"id": 2, "name": "Deutsch"},
      "grades": [],
    }
  ]
};

const _mathWithTwoGrades = {
  "subjects": [
    {
      "subject": {"id": 1, "name": "Mathematik"},
      "grades": [
        {
          "grade": "7.50",
          "weight": 100,
          "date": "2021-01-04",
          "cancelled": 0,
          "type": "Schularbeit",
        },
        {
          "grade": "8.00",
          "weight": 50,
          "date": "2021-02-10",
          "cancelled": 0,
          "type": "Test",
        }
      ],
    }
  ]
};

void main() {
  group('grades reducer — loaded action', () {
    test('new subject is added to empty state', () async {
      final store = _makeStore();
      await store.actions.gradesActions.loaded(_payload(_mathSubject));

      expect(store.state.gradesState.subjects.length, 1);
      expect(store.state.gradesState.subjects.first.name, 'Mathematik');
    });

    test('grades are stored for the correct semester', () async {
      final store = _makeStore();
      await store.actions.gradesActions.loaded(_payload(_mathSubject));

      final subject = store.state.gradesState.subjects.first;
      expect(subject.gradesAll[Semester.first], isNotNull);
      expect(subject.gradesAll[Semester.first]!.length, 1);
    });

    test('existing subject grades are updated', () async {
      final store = _makeStore();
      // Load once with one grade
      await store.actions.gradesActions.loaded(_payload(_mathSubject));
      expect(store.state.gradesState.subjects.first.gradesAll[Semester.first]!.length, 1);

      // Reload with two grades
      await store.actions.gradesActions.loaded(_payload(_mathWithTwoGrades));
      expect(store.state.gradesState.subjects.length, 1);
      expect(store.state.gradesState.subjects.first.gradesAll[Semester.first]!.length, 2);
    });

    test('subjects removed from response are removed from state', () async {
      final store = _makeStore();
      // Load Mathematik and Deutsch
      await store.actions.gradesActions.loaded(_payload({
        "subjects": [
          ..._mathSubject["subjects"]!,
          ..._germanSubject["subjects"]!,
        ]
      }));
      expect(store.state.gradesState.subjects.length, 2);

      // Reload with only Mathematik
      await store.actions.gradesActions.loaded(_payload(_mathSubject));
      expect(store.state.gradesState.subjects.length, 1);
      expect(store.state.gradesState.subjects.first.name, 'Mathematik');
    });

    test('multiple semesters coexist for same subject', () async {
      final store = _makeStore();
      await store.actions.gradesActions
          .loaded(_payload(_mathSubject, semester: Semester.first));
      await store.actions.gradesActions
          .loaded(_payload(_mathWithTwoGrades, semester: Semester.second));

      final subject = store.state.gradesState.subjects.first;
      expect(subject.gradesAll[Semester.first]!.length, 1);
      expect(subject.gradesAll[Semester.second]!.length, 2);
    });

    test('loading flag is cleared after loaded', () async {
      // Start with loading = true in initial state to avoid dispatching
      // gradesActions.load (which triggers middleware HTTP calls)
      final store = Store<AppState, AppStateBuilder, AppActions>(
        appReducerBuilder.build(),
        AppState((b) => b.gradesState.loading = true),
        AppActions(),
        middleware: middleware(includeErrorMiddleware: false),
      );
      expect(store.state.gradesState.loading, true);
      await store.actions.gradesActions.loaded(_payload(_mathSubject));
      expect(store.state.gradesState.loading, false);
    });

    test('loadFailed clears loading flag', () async {
      final store = Store<AppState, AppStateBuilder, AppActions>(
        appReducerBuilder.build(),
        AppState((b) => b.gradesState.loading = true),
        AppActions(),
        middleware: middleware(includeErrorMiddleware: false),
      );
      expect(store.state.gradesState.loading, true);
      await store.actions.gradesActions.loadFailed();
      expect(store.state.gradesState.loading, false);
    });
  });
}
