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

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/container/calendar_container.dart';
import 'package:dr/container/settings_page.dart';
import 'package:dr/data.dart';
import 'package:dr/main.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../fixtures/api_fixtures.dart';

class _TestCalendarNotifier extends CalendarNotifier {
  final CalendarState initialState;
  _TestCalendarNotifier(this.initialState);

  @override
  CalendarState build() => initialState;
}

class _TestSettingsNotifier extends SettingsNotifier {
  final SettingsState initial;
  _TestSettingsNotifier(this.initial);

  @override
  SettingsState build() => initial;
}

CalendarState _buildCalendarState({
  required bool hasSubjectWithoutNick,
}) {
  return CalendarState(
    (b) {
      b
        ..currentMonday = UtcDateTime(2021, 2, 20)
        ..days = MapBuilder(
          <UtcDateTime, CalendarDay>{
            UtcDateTime(2021, 2, 20): CalendarDay(
              (b) => b
                ..date = UtcDateTime(2021, 2, 20)
                ..hours = ListBuilder(
                  <CalendarHour>[
                    CalendarHour(
                      (b) => b
                        ..subject = "Fach1"
                        ..fromHour = 1
                        ..toHour = 2
                        ..rooms = ListBuilder()
                        ..timeSpans = ListBuilder(<TimeSpan>[
                          TimeSpan((b) => b
                            ..from = UtcDateTime(2022, 9, 5, 22)
                            ..to = UtcDateTime(2022, 9, 5, 23))
                        ])
                        ..homeworkExams = ListBuilder(
                          <HomeworkExam>[
                            HomeworkExam(
                              (b) => b
                                ..deadline = UtcDateTime.now()
                                ..hasGradeGroupSubmissions = false
                                ..hasGrades = false
                                ..homework = false
                                ..id = 5
                                ..name = "Foo"
                                ..online = false
                                ..typeId = 500
                                ..typeName = "Hausaufgabe"
                                ..warning = false,
                            )
                          ],
                        ),
                    ),
                  ],
                ),
            ),
          },
        );
    },
  );
}

// Demo state parsed in setUpAll from assets/demo/capture.json (KW 2026-05-11).
late CalendarState _demoState;

Future<void> main() async {
  setUpAll(() async {
    await loadFixtures();
    await loadAppFonts();
    // Use a temporary container to access parseLoaded (visibleForTesting).
    final container = ProviderContainer();
    final notifier = container.read(calendarProvider.notifier);
    final raw = fixtureFor(
      'api/calendar/student',
      params: {'startDate': '2026-05-11'},
    ) as Map<String, dynamic>;
    final days = notifier.parseLoaded(raw);
    container.dispose();
    _demoState = CalendarState(
      (b) => b
        ..currentMonday = UtcDateTime(2026, 5, 11)
        ..days = MapBuilder(days),
    );
  });

  Widget getCalendar(
      {required bool nicksBarEnabled, required bool hasSubjctWithoutNick}) {
    navigatorKey = GlobalKey();
    final calendarState =
        _buildCalendarState(hasSubjectWithoutNick: hasSubjctWithoutNick);
    final container = ProviderContainer(
      overrides: [
        calendarProvider.overrideWith(
          () => _TestCalendarNotifier(calendarState),
        ),
        noInternetProvider.overrideWith(NoInternetNotifier.new),
        settingsProvider.overrideWith(
          () => _TestSettingsNotifier(
            SettingsState(
              showCalendarNicksBar: nicksBarEnabled,
              subjectNicks: !hasSubjctWithoutNick ? {"Fach1": "F"} : null,
            ),
          ),
        ),
      ],
    );
    pc.providerContainer = container;
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: CalendarContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale("de"),
        ],
        onGenerateRoute: (settings) {
          assert(settings.name == "/settings");
          return MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (context) => SettingsPageContainer(),
          );
        },
      ),
    );
  }

  group('Edit Subjects nicks bar', () {
    group('when disabled', () {
      testGoldens('and subject without nick', (WidgetTester tester) async {
        final widget =
            getCalendar(nicksBarEnabled: false, hasSubjctWithoutNick: true);
        await tester.pumpWidget(widget);
        await expectLater(find.byType(CalendarContainer),
            matchesGoldenFile("bar_not_shown.png"));
      });
      testGoldens('and no subject without nick', (WidgetTester tester) async {
        final widget =
            getCalendar(nicksBarEnabled: false, hasSubjctWithoutNick: false);
        await tester.pumpWidget(widget);
        await expectLater(find.byType(CalendarContainer),
            matchesGoldenFile("bar_not_shown_nick.png"));
      });
    });
    group('when enabled', () {
      testGoldens('and subject without nick', (WidgetTester tester) async {
        final widget =
            getCalendar(nicksBarEnabled: true, hasSubjctWithoutNick: true);
        await tester.pumpWidget(widget);
        await expectLater(
            find.byType(CalendarContainer), matchesGoldenFile("bar_shown.png"));
      });
      testGoldens('and no subject without nick', (WidgetTester tester) async {
        final widget =
            getCalendar(nicksBarEnabled: true, hasSubjctWithoutNick: false);
        await tester.pumpWidget(widget);
        await expectLater(find.byType(CalendarContainer),
            matchesGoldenFile("bar_not_shown_nick.png"));
      });
    });
  });
  testWidgets('jump to current week', (WidgetTester tester) async {
    final calendarState = CalendarState(
      (b) => b..currentMonday = UtcDateTime(2021, 1, 20),
    );
    final container = ProviderContainer(
      overrides: [
        calendarProvider.overrideWith(
          () => _TestCalendarNotifier(calendarState),
        ),
        noInternetProvider.overrideWith(NoInternetNotifier.new),
      ],
    );
    pc.providerContainer = container;
    addTearDown(container.dispose);
    final widget = UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CalendarContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale("de"),
        ],
      ),
    );
    // the shown week is the previous week
    mockNow = UtcDateTime(2021, 1, 27);
    await tester.pumpWidget(widget);
    // one circular progressindicator on top, one on the body (none for the detail view - it should not be built)
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(find.text("Aktuelle Woche"), findsOneWidget);
    await tester.tap(find.text("Aktuelle Woche"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // weeks are animating, so there are two weeks that show a progress indicator
    expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, "Aktuelle Woche")).onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, "Aktuelle Woche")).onPressed, isNull);
  });

  testWidgets("tapping the bar opens settings", (WidgetTester tester) async {
    final widget =
        getCalendar(nicksBarEnabled: true, hasSubjctWithoutNick: true);
    await tester.pumpWidget(
      DynamicTheme(
        data: (brightness, overridePlatform, seedColor) {
          return ThemeData(
            primarySwatch: Colors.deepOrange,
            brightness: brightness,
          );
        },
        themedWidgetBuilder: (context, data) => widget,
      ),
    );
    await tester.tap(find.textContaining("Kürzel"));
    await tester.pumpAndSettle();
    // a dialog should be opened
    expect(find.byType(InfoDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(InfoDialog),
        matching: find.text("Kürzel hinzufügen"),
      ),
      findsOneWidget,
    );
    expect(find.text("Fach1"), findsOneWidget);
  });

  group('demo data KW 2026-05-11', () {
    Widget getDemoCalendar() {
      navigatorKey = GlobalKey();
      final container = ProviderContainer(
        overrides: [
          calendarProvider.overrideWith(
            () => _TestCalendarNotifier(_demoState),
          ),
          noInternetProvider.overrideWith(NoInternetNotifier.new),
          settingsProvider.overrideWith(
            () => _TestSettingsNotifier(SettingsState(subjectNicks: {})),
          ),
        ],
      );
      pc.providerContainer = container;
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: CalendarContainer(),
          theme: ThemeData(primarySwatch: Colors.deepOrange),
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale("de")],
        ),
      );
    }

    testWidgets('shows all 5 weekday headers', (tester) async {
      await tester.pumpWidget(getDemoCalendar());
      await tester.pump();
      expect(find.text('Mo'), findsOneWidget);
      expect(find.text('Di'), findsOneWidget);
      expect(find.text('Mi'), findsOneWidget);
      expect(find.text('Do'), findsOneWidget);
      expect(find.text('Fr'), findsOneWidget);
    });

    testWidgets('shows date 11.05 for Monday', (tester) async {
      await tester.pumpWidget(getDemoCalendar());
      await tester.pump();
      expect(find.text('11.05'), findsOneWidget);
    });

    testWidgets('shows subject Deutsch', (tester) async {
      await tester.pumpWidget(getDemoCalendar());
      await tester.pump();
      expect(find.text('Deutsch'), findsWidgets);
    });

    testWidgets('shows subject Mathematik', (tester) async {
      await tester.pumpWidget(getDemoCalendar());
      await tester.pump();
      expect(find.text('Mathematik'), findsWidgets);
    });

    testWidgets('shows teacher name Testfrau', (tester) async {
      await tester.pumpWidget(getDemoCalendar());
      await tester.pump();
      expect(find.text('Testfrau'), findsWidgets);
    });

    testGoldens('demo week view golden', (tester) async {
      await tester.pumpWidget(getDemoCalendar());
      await tester.pump();
      await expectLater(
        find.byType(CalendarContainer),
        matchesGoldenFile('demo_week.png'),
      );
    });
  });
}
