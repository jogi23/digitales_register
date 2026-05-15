// Copyright (C) 2021 Michael Debertol
// Copyright (C) 2026 Johannes Feichter
//
// This file is part of digitales_register.
//
// digitales_register is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// digitales_register is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with digitales_register.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:core';

import 'package:built_collection/built_collection.dart';
import 'package:built_redux/built_redux.dart';
import 'package:dr/actions/app_actions.dart';
import 'package:dr/app_state.dart' hide LoginState;
import 'package:dr/container/days_container.dart';
import 'package:dr/data.dart';
import 'package:dr/main.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/reducer/reducer.dart';
import 'package:dr/ui/days.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:dr/ui/sidebar.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

class MockWrapper extends Mock implements Wrapper {}

class _TestDashboardNotifier extends DashboardNotifier {
  _TestDashboardNotifier(this._initialState);
  final DashboardState _initialState;
  @override
  DashboardState build() => _initialState;
}

class _TestSettingsNotifier extends SettingsNotifier {
  final SettingsState initial;

  _TestSettingsNotifier(this.initial);

  @override
  SettingsState build() => initial;
}

class _TestLoginNotifier extends LoginNotifier {
  final LoginState initial;

  _TestLoginNotifier(this.initial);

  @override
  LoginState build() => initial;
}

class _TrueNoInternetNotifier extends NoInternetNotifier {
  @override
  bool build() => true;
}

class _TestNoInternetNotifier extends NoInternetNotifier {
  @override
  bool build() => false;

  @override
  void setNoInternet(bool value) => state = value;
}

Future<void> main() async {
  testGoldens('Open drawer in phone mode', (WidgetTester tester) async {
    ScaffoldState getScaffoldState() {
      return tester.state(find.byType(Scaffold).at(0));
    }

    final widget = ProviderScope(
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(home: DaysContainer()),
      ),
    );
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 300,
          child: widget,
        ),
      ),
    );
    expect(getScaffoldState().isDrawerOpen, isFalse);
    // scroll vertically
    await tester.fling(find.byType(Scaffold).at(0), const Offset(0, 500), 1000);
    await tester.pumpAndSettle();
    expect(getScaffoldState().isDrawerOpen, isFalse);
    // scroll vertically, but also a bit horizontally
    await tester.fling(
        find.byType(Scaffold).at(0), const Offset(30, 100), 1000);
    await tester.pumpAndSettle();
    expect(getScaffoldState().isDrawerOpen, isFalse);
    // scroll mostly horizontally from left edge — triggers drawer edge drag
    final scaffoldRect = tester.getRect(find.byType(Scaffold).at(0));
    await tester.flingFrom(
      Offset(scaffoldRect.left + 10, scaffoldRect.center.dy),
      const Offset(100, 30),
      1000,
    );
    await tester.pumpAndSettle();
    expect(getScaffoldState().isDrawerOpen, isTrue);
  });
  testWidgets('Home page shows no internet message',
      (WidgetTester tester) async {
    final widget = ProviderScope(
      overrides: [
        noInternetProvider.overrideWith(_TrueNoInternetNotifier.new),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState((b) => b.noInternet = true),
          AppActions(),
        ),
        child: MaterialApp(home: DaysContainer()),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.text("Keine Verbindung"), findsNWidgets(2));
    expect(find.byType(NoInternet), findsOneWidget);
    expect(find.text("Vergangenheit"), findsOneWidget);
    expect(find.text("Zukunft"), findsNothing);
    expect(find.byType(Sidebar), findsOneWidget);
  });

  testGoldens('Long user name is wrapped', (WidgetTester tester) async {
    const longName = "Michael Debertol Elternaccount-1";
    final widget = ProviderScope(
      overrides: [
        loginProvider.overrideWith(
          () => _TestLoginNotifier(const LoginState(username: longName)),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(
            (b) => b..loginState.username = longName,
          ),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await expectLater(find.text(longName), matchesGoldenFile('long_name.png'));
  });

  testGoldens('shows circular progress indicator if there are no entries',
      (WidgetTester tester) async {
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState((b) => b..loading = true),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await expectLater(
        find.byType(DaysWidget), matchesGoldenFile("loading_empty.png"));
  });
  testGoldens(
      'shows linear progress indicator if there are one or more entries',
      (WidgetTester tester) async {
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState(
              (b) => b
                ..loading = true
                ..allDays = ListBuilder(
                  <Day>[
                    Day(
                      (b) => b
                        ..date = UtcDateTime.now()
                        ..deletedHomework = ListBuilder()
                        ..homework = ListBuilder()
                        ..lastRequested = UtcDateTime.now(),
                    ),
                  ],
                ),
            ),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(DayWidget), findsOneWidget);
    await expectLater(
        find.byType(ReduxProvider), matchesGoldenFile("loading_not_empty.png"));
  });

  testGoldens('Multiple Entries', (WidgetTester tester) async {
    final now = UtcDateTime(2050);
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState(
              (b) => b.allDays = ListBuilder(
                <Day>[
                  Day(
                    (b) => b
                      ..date = now
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder(<Homework>[
                        Homework(
                          (b) => b
                            ..checkable = true
                            ..checked = false
                            ..deleteable = false
                            ..deleted = false
                            ..firstSeen = now
                            ..id = 1
                            ..isChanged = false
                            ..isNew = false
                            ..type = HomeworkType.lessonHomework
                            ..title = "Test"
                            ..subtitle = "Subtitle"
                            ..gradeFormatted = "7/9",
                        ),
                      ])
                      ..lastRequested = now,
                  ),
                  Day(
                    (b) => b
                      ..date = now.add(const Duration(days: 1))
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder()
                      ..lastRequested = now,
                  ),
                  Day(
                    (b) => b
                      ..date = now.add(const Duration(days: 2))
                      ..deletedHomework = ListBuilder(
                        <Homework>[
                          Homework(
                            (b) => b
                              ..checkable = true
                              ..checked = true
                              ..deleteable = false
                              ..deleted = true
                              ..firstSeen = now
                              ..id = 1234
                              ..isChanged = false
                              ..isNew = false
                              ..type = HomeworkType.lessonHomework
                              ..title = "Titel"
                              ..subtitle = "Subtitle",
                          ),
                        ],
                      )
                      ..homework = ListBuilder(
                        <Homework>[
                          Homework(
                            (b) => b
                              ..checkable = true
                              ..checked = true
                              ..deleteable = false
                              ..deleted = false
                              ..firstSeen = now
                              ..id = 0
                              ..isChanged = false
                              ..isNew = false
                              ..type = HomeworkType.lessonHomework
                              ..title = "Title"
                              ..subtitle = "Subtitle",
                          ),
                          Homework(
                            (b) => b
                              ..checkable = true
                              ..checked = false
                              ..deleteable = false
                              ..deleted = false
                              ..firstSeen = now
                              ..id = 1
                              ..isChanged = false
                              ..isNew = false
                              ..type = HomeworkType.lessonHomework
                              ..title = "Test"
                              ..subtitle = "Subtitle",
                          ),
                        ],
                      )
                      ..lastRequested = now,
                  ),
                  Day(
                    (b) => b
                      ..date = now.add(const Duration(days: 3))
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder()
                      ..lastRequested = now,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(
              primarySwatch: Colors.teal, brightness: Brightness.dark),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(DayWidget), findsNWidgets(4));
    expect(find.byType(ItemWidget), findsNWidgets(3));
    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(DaysWidget), matchesGoldenFile("multiple_entries.png"));
  });

  testGoldens('dark mode', (WidgetTester tester) async {
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState(
              (b) => b.allDays = ListBuilder(
                <Day>[
                  Day(
                    (b) => b
                      ..date = UtcDateTime.now()
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder()
                      ..lastRequested = UtcDateTime.now(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(
              primarySwatch: Colors.teal, brightness: Brightness.dark),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(DayWidget), findsOneWidget);
    await expectLater(
        find.byType(DaysWidget), matchesGoldenFile("dark_not_empty.png"));
  });

  testWidgets('tooltips', (WidgetTester tester) async {
    const username = "Michael Debertol";
    final widget = ProviderScope(
      overrides: [
        loginProvider.overrideWith(
          () => _TestLoginNotifier(const LoginState(username: username)),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(
            (b) => b.loginState.username = username,
          ),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(
              primarySwatch: Colors.teal, brightness: Brightness.dark),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.byTooltip(username), findsOneWidget);
    expect(find.byTooltip("Merkheft"), findsOneWidget);
    expect(find.byTooltip("Bewertungen"), findsOneWidget);
    expect(find.byTooltip("Absenzen"), findsOneWidget);
    expect(find.byTooltip("Kalender"), findsOneWidget);
    expect(find.byTooltip("Einstellungen"), findsOneWidget);
    expect(find.byTooltip("Abmelden"), findsOneWidget);
    expect(find.byTooltip("Einklappen"), findsOneWidget);
    expect(find.byTooltip("Ausklappen"), findsNothing);
  });

  testWidgets('correct collapse label', (WidgetTester tester) async {
    final widget = ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          () => _TestSettingsNotifier(
            SettingsState((b) => b.drawerFullyExpanded = false),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(
              primarySwatch: Colors.teal, brightness: Brightness.dark),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.byTooltip("Einklappen"), findsNothing);
    expect(find.byTooltip("Ausklappen"), findsOneWidget);
  });

  testGoldens('new entries are animated', (WidgetTester tester) async {
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState(
              (b) => b.allDays = ListBuilder(
                <Day>[
                  Day(
                    (b) => b
                      ..date = UtcDateTime.now()
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder(<Homework>[
                        Homework(
                          (b) => b
                            ..checkable = true
                            ..checked = false
                            ..deleteable = false
                            ..deleted = false
                            ..firstSeen = UtcDateTime.now()
                            ..id = 0
                            ..isChanged = false
                            ..isNew = false
                            ..type = HomeworkType.lessonHomework
                            ..title = "Title"
                            ..subtitle = "Subtitle",
                        ),
                      ])
                      ..lastRequested = UtcDateTime.now(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          appReducerBuilder.build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(primarySwatch: Colors.deepOrange),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await expectLater(find.byType(DaysWidget),
        matchesGoldenFile("new_entry_not_yet_animating.png"));
    // start the entry animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    // should now be halfway opened
    expect(find.byType(ItemWidget), findsOneWidget);
    await expectLater(
        find.byType(DaysWidget), matchesGoldenFile("new_entry_animating.png"));
    await tester.pump(const Duration(milliseconds: 200));
    // should be fully opened
    await tester.pump();
    expect(find.byType(ItemWidget), findsOneWidget);
    await expectLater(
        find.byType(DaysWidget), matchesGoldenFile("new_entry_animated.png"));
  });

  testGoldens('animation for reminder deletion', (WidgetTester tester) async {
    wrapper = MockWrapper();
    when(() => wrapper.send(any(), args: any(named: 'args')))
        .thenAnswer((_) async => <String, dynamic>{'success': true});
    when(() => wrapper.noInternet).thenReturn(false);
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState(
              (b) => b.allDays = ListBuilder(
                <Day>[
                  Day(
                    (b) => b
                      ..date = UtcDateTime.now()
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder(<Homework>[
                        Homework(
                          (b) => b
                            ..checkable = true
                            ..checked = true
                            ..deleteable = true
                            ..deleted = false
                            ..firstSeen = UtcDateTime.now()
                                // do not show a entry animation
                                .subtract(const Duration(seconds: 10))
                            ..id = 0
                            ..isChanged = false
                            ..isNew = false
                            ..type = HomeworkType.homework
                            ..title = "Title"
                            ..subtitle = "Subtitle",
                        ),
                      ])
                      ..lastRequested = UtcDateTime.now(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          appReducerBuilder.build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(primarySwatch: Colors.deepOrange),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(ItemWidget), findsOneWidget);
    await expectLater(
        find.byType(DaysWidget), matchesGoldenFile("reminder.png"));
    // trigger the close animation
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // should now be halfway closed
    expect(find.byType(ItemWidget), findsOneWidget);
    await expectLater(
        find.byType(DaysWidget), matchesGoldenFile("reminder_deleting.png"));
    await tester.pump(const Duration(milliseconds: 200));
    // should be gone
    await tester.pump();
    expect(find.byType(ItemWidget), findsNothing);
  });

  testGoldens('animation for checking an item', (WidgetTester tester) async {
    wrapper = MockWrapper();
    when(() => wrapper.send(any(), args: any(named: 'args')))
        .thenAnswer((_) async => <String, dynamic>{'success': true});
    when(() => wrapper.noInternet).thenReturn(false);
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState(
              (b) => b.allDays = ListBuilder(
                <Day>[
                  Day(
                    (b) => b
                      ..date = UtcDateTime.now()
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder(<Homework>[
                        Homework(
                          (b) => b
                            ..checkable = true
                            ..checked = false
                            ..deleteable = true
                            ..deleted = false
                            ..firstSeen = UtcDateTime.now()
                                // do not show a entry animation
                                .subtract(const Duration(seconds: 10))
                            ..id = 0
                            ..isChanged = false
                            ..isNew = false
                            ..type = HomeworkType.homework
                            ..title = "Title"
                            ..subtitle = "Subtitle",
                        ),
                      ])
                      ..lastRequested = UtcDateTime.now(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          appReducerBuilder.build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(primarySwatch: Colors.deepOrange),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(ItemWidget), findsOneWidget);
    // trigger the checkbox animation
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    // should now be halfway checked
    await expectLater(find.byType(DaysWidget),
        matchesGoldenFile("item_checking_animation.png"));
    await tester.pump(const Duration(milliseconds: 250));
    // should be fully checked
    await tester.pump();
    await expectLater(
        find.byType(DaysWidget), matchesGoldenFile("item_checked.png"));
  });

  testGoldens('colored background when setting enabled',
      (WidgetTester tester) async {
    final now = UtcDateTime(2050);
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState(
              (b) => b.allDays = ListBuilder(
                <Day>[
                  Day(
                    (b) => b
                      ..date = now
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder(<Homework>[
                        Homework(
                          (b) => b
                            ..checkable = false
                            ..checked = false
                            ..deleteable = false
                            ..deleted = false
                            ..firstSeen = now
                            ..id = 1
                            ..isChanged = false
                            ..isNew = false
                            ..label = "Mathematik"
                            ..type = HomeworkType.lessonHomework
                            ..title = "Seite 42 aufgabe 3"
                            ..subtitle = "Für morgen",
                        ),
                        Homework(
                          (b) => b
                            ..checkable = false
                            ..checked = false
                            ..deleteable = false
                            ..deleted = false
                            ..firstSeen = now
                            ..id = 2
                            ..isChanged = false
                            ..isNew = false
                            ..label = "Deutsch"
                            ..type = HomeworkType.lessonHomework
                            ..title = "Aufsatz schreiben"
                            ..subtitle = "Für morgen",
                        ),
                        Homework(
                          (b) => b
                            ..checkable = false
                            ..checked = false
                            ..deleteable = false
                            ..deleted = false
                            ..firstSeen = now
                            ..id = 3
                            ..isChanged = false
                            ..isNew = false
                            // no matching theme → transparent
                            ..label = "Sport"
                            ..type = HomeworkType.lessonHomework
                            ..title = "Turnschuhe mitbringen"
                            ..subtitle = "Für morgen",
                        ),
                      ])
                      ..lastRequested = now,
                  ),
                ],
              ),
            ),
          ),
        ),
        settingsProvider.overrideWith(
          () => _TestSettingsNotifier(
            SettingsState(
              (b) => b
                ..dashboardColorBorders = true
                ..subjectThemes = MapBuilder<String, SubjectTheme>({
                  'Mathematik': SubjectTheme(
                      (b) => b..thick = 2..color = Colors.blue.value),
                  'Deutsch': SubjectTheme(
                      (b) => b..thick = 2..color = Colors.green.value),
                }),
            ),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(primarySwatch: Colors.deepOrange),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(DaysWidget),
        matchesGoldenFile("colored_background_enabled.png"));
  });

  testGoldens('no colored background when setting disabled',
      (WidgetTester tester) async {
    final now = UtcDateTime(2050);
    final widget = ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          () => _TestDashboardNotifier(
            DashboardState(
              (b) => b.allDays = ListBuilder(
                <Day>[
                  Day(
                    (b) => b
                      ..date = now
                      ..deletedHomework = ListBuilder()
                      ..homework = ListBuilder(<Homework>[
                        Homework(
                          (b) => b
                            ..checkable = false
                            ..checked = false
                            ..deleteable = false
                            ..deleted = false
                            ..firstSeen = now
                            ..id = 1
                            ..isChanged = false
                            ..isNew = false
                            ..label = "Mathematik"
                            ..type = HomeworkType.lessonHomework
                            ..title = "Seite 42 aufgabe 3"
                            ..subtitle = "Für morgen",
                        ),
                      ])
                      ..lastRequested = now,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          ReducerBuilder<AppState, AppStateBuilder>().build(),
          AppState(
            (b) => b.settingsState
              ..dashboardColorBorders = false
              ..subjectThemes = MapBuilder<String, SubjectTheme>({
                'Mathematik': SubjectTheme(
                    (b) => b..thick = 2..color = Colors.blue.value),
              }),
          ),
          AppActions(),
        ),
        child: MaterialApp(
          home: DaysContainer(),
          theme: ThemeData(primarySwatch: Colors.deepOrange),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(DaysWidget),
        matchesGoldenFile("colored_background_disabled.png"));
  });

  testWidgets("check box when offline but not yet in offline mode",
      (WidgetTester tester) async {
    secureStorage = const FlutterSecureStorage();
    scaffoldMessengerKey = GlobalKey();
    final initialDashboardState = DashboardState(
      (b) => b.allDays = ListBuilder(
        <Day>[
          Day(
            (b) => b
              ..date = UtcDateTime.now()
              ..deletedHomework = ListBuilder()
              ..homework = ListBuilder(<Homework>[
                Homework(
                  (b) => b
                    ..checkable = true
                    ..checked = false
                    ..deleteable = true
                    ..deleted = false
                    ..firstSeen = UtcDateTime(2021, 2, 2)
                    ..id = 0
                    ..isChanged = false
                    ..isNew = false
                    ..type = HomeworkType.homework
                    ..title = "Title"
                    ..subtitle = "Subtitle",
                ),
              ])
              ..lastRequested = UtcDateTime.now(),
          ),
        ],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        dashboardProvider
            .overrideWith(() => _TestDashboardNotifier(initialDashboardState)),
        noInternetProvider.overrideWith(_TestNoInternetNotifier.new),
      ],
    );
    pc.providerContainer = container;
    addTearDown(container.dispose);
    final store = Store<AppState, AppStateBuilder, AppActions>(
      appReducerBuilder.build(),
      AppState(),
      AppActions(),
      middleware: middleware(includeErrorMiddleware: false),
    );
    final widget = UncontrolledProviderScope(
      container: container,
      child: ReduxProvider(
        store: store,
        child: MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: DaysContainer(),
          theme: ThemeData(primarySwatch: Colors.deepOrange),
        ),
      ),
    );
    wrapper = MockWrapper();
    when(() => wrapper.noInternet).thenReturn(true);
    when(() => wrapper.refreshNoInternet())
        .thenAnswer((_) => Future.value(true));
    when(() => wrapper.send(
          "api/student/dashboard/toggle_reminder",
          args: {
            "id": 0,
            "type": "homework",
            "value": true,
          },
        )).thenAnswer((_) => Future<dynamic>.value());
    await tester.pumpWidget(widget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    container.read(noInternetProvider.notifier).setNoInternet(true);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
  });
}
