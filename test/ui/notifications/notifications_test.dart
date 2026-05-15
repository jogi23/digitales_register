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

import 'package:built_redux/built_redux.dart';
import 'package:dr/actions/app_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/container/notification_icon_container.dart';
import 'package:dr/container/notifications_page_container.dart';
import 'package:dr/data.dart';
import 'package:dr/main.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/notifications_provider.dart';
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/reducer/reducer.dart';
import 'package:dr/ui/notifications_page.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

class MockWrapper extends Mock implements Wrapper {}

class _TestNotificationsNotifier extends NotificationsNotifier {
  _TestNotificationsNotifier(this._initialState);
  final NotificationsState _initialState;
  @override
  NotificationsState build() => _initialState;
}

Widget _buildTestWidget({
  required NotificationsState initialState,
  Widget? child,
}) {
  return ProviderScope(
    overrides: [
      notificationsProvider.overrideWith(
        () => _TestNotificationsNotifier(initialState),
      ),
    ],
    child: ReduxProvider(
      store: Store<AppState, AppStateBuilder, AppActions>(
        ReducerBuilder<AppState, AppStateBuilder>().build(),
        AppState(),
        AppActions(),
      ),
      child: MaterialApp(
        home: child ?? NotificationPageContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
      ),
    ),
  );
}

void main() {
  testGoldens('Notification icon shows badge', (WidgetTester tester) async {
    final notifications = [
      Notification(
        (b) => b
          ..id = 0
          ..title = "title"
          ..timeSent = UtcDateTime.now(),
      ),
    ];
    final widget = _buildTestWidget(
      initialState: NotificationsState(notifications: notifications),
      child: Material(child: NotificationIconContainer()),
    );
    await tester.pumpWidget(widget);
    expect(find.byIcon(Icons.notifications), findsOneWidget);
    expect(find.text("1"), findsOneWidget);
    await expectLater(find.byType(NotificationIconContainer),
        matchesGoldenFile("icon_before_animation.png"));
    await tester.pump(const Duration(milliseconds: 25));
    await expectLater(find.byType(NotificationIconContainer),
        matchesGoldenFile("icon_animating.png"));
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(NotificationIconContainer),
        matchesGoldenFile("icon_animated.png"));
  });
  testGoldens('Notification page', (WidgetTester tester) async {
    final notifications = [
      Notification(
        (b) => b
          ..id = 0
          ..title = "title1"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
      Notification(
        (b) => b
          ..id = 0
          ..title = "title2"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
      Notification(
        (b) => b
          ..id = 0
          ..title = "title3"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
    ];
    final widget = _buildTestWidget(
      initialState: NotificationsState(notifications: notifications),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(NotificationWidget), findsNWidgets(3));
    await expectLater(
        find.byType(NotificationPage), matchesGoldenFile("page.png"));
  });

  testGoldens('Notification page delete single animation',
      (WidgetTester tester) async {
    final notifications = [
      Notification(
        (b) => b
          ..id = 0
          ..title = "title1"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
      Notification(
        (b) => b
          ..id = 0
          ..title = "title2"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
      Notification(
        (b) => b
          ..id = 0
          ..title = "title3"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
    ];
    final widget = _buildTestWidget(
      initialState: NotificationsState(notifications: notifications),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(NotificationWidget), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.done).first);
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("notification_not_yet_deleted.png"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("notification_deleting.png"));
    await tester.pump(const Duration(milliseconds: 151));
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("notification_deleted.png"));
    expect(find.byType(NotificationWidget), findsNWidgets(2));
  });
  testGoldens('Notification page delete all animation',
      (WidgetTester tester) async {
    final notifications = [
      Notification(
        (b) => b
          ..id = 0
          ..title = "title1"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
      Notification(
        (b) => b
          ..id = 0
          ..title = "title2"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
      Notification(
        (b) => b
          ..id = 0
          ..title = "title3"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
    ];
    final widget = _buildTestWidget(
      initialState: NotificationsState(notifications: notifications),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(NotificationWidget), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.done_all));
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("notifications_not_yet_deleted.png"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("notifications_deleting.png"));
    await tester.pump(const Duration(milliseconds: 151));
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("notifications_deleted.png"));
    expect(find.byType(NotificationWidget), findsNothing);
  });
  testGoldens('Notification page delete last animation',
      (WidgetTester tester) async {
    final notifications = [
      Notification(
        (b) => b
          ..id = 0
          ..title = "title1"
          ..timeSent = UtcDateTime(2020, 1, 2),
      ),
    ];
    final widget = _buildTestWidget(
      initialState: NotificationsState(notifications: notifications),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(NotificationWidget), findsOneWidget);
    await tester.tap(find.byIcon(Icons.done));
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("single_notification_not_yet_deleted.png"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("single_notification_deleting.png"));
    await tester.pump(const Duration(milliseconds: 151));
    await expectLater(find.byType(NotificationPage),
        matchesGoldenFile("single_notification_deleted.png"));
    expect(find.byType(NotificationWidget), findsNothing);
  });

  testWidgets('mark other types as read', (WidgetTester tester) async {
    wrapper = MockWrapper();

    final notifications = [
      Notification(
        (b) => b
          ..id = 0
          ..title = "title0"
          ..timeSent = UtcDateTime(2021, 3, 12),
      ),
      Notification(
        (b) => b
          ..id = 1
          ..title = "title1"
          ..timeSent = UtcDateTime(2021, 3, 12),
      ),
      Notification(
        (b) => b
          ..id = 2
          ..title = "title2"
          ..timeSent = UtcDateTime(2021, 3, 12)
          ..objectId = 25
          ..type = "message",
      ),
      Notification(
        (b) => b
          ..id = 3
          ..title = "title3"
          ..timeSent = UtcDateTime(2021, 3, 12)
          ..objectId = 50
          ..type = "message",
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        notificationsProvider.overrideWith(
          () => _TestNotificationsNotifier(
            NotificationsState(notifications: notifications),
          ),
        ),
      ],
    );
    pc.providerContainer = container;
    addTearDown(container.dispose);

    // An attempt to do networking will result in 400 and a "no internet" snack bar
    scaffoldMessengerKey = GlobalKey();

    final widget = UncontrolledProviderScope(
      container: container,
      child: ReduxProvider(
        store: Store<AppState, AppStateBuilder, AppActions>(
          appReducerBuilder.build(),
          AppState(),
          AppActions(),
          middleware: middleware(includeErrorMiddleware: false),
        ),
        child: MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: NotificationPageContainer(),
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);

    // delete the 0th notification
    when(
      () => wrapper.send(
        "api/notification/markAsRead",
        args: {
          "id": isIn([0, null]),
        },
      ),
    ).thenAnswer(
      (invocation) => Future<dynamic>.value(""),
    );
    expect(find.text("title0"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.done).first);
    await tester.pumpAndSettle();
    expect(find.text("title0"), findsNothing);
    expect(
      container.read(notificationsProvider).notifications,
      isNot(contains(notifications[0])),
    );

    // delete all
    when(
      () => wrapper.send(
        "api/notification/markAsRead",
        args: {},
      ),
    ).thenAnswer(
      (invocation) => Future<dynamic>.value(""),
    );
    when(
      () => wrapper.send(
        "api/message/markAsRead",
        args: {"messageId": 25},
      ),
    ).thenAnswer(
      (invocation) => Future<dynamic>.value(""),
    );
    when(
      () => wrapper.send(
        "api/message/markAsRead",
        args: {"messageId": 50},
      ),
    ).thenAnswer(
      (invocation) => Future<dynamic>.value(""),
    );
    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();
    expect(find.textContaining("title"), findsNothing);
    expect(
      container.read(notificationsProvider).notifications,
      isEmpty,
    );
  });
}
