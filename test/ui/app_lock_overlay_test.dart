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

import 'package:dr/providers/app_lock_provider.dart';
import 'package:dr/services/app_lock_platform.dart';
import 'package:dr/services/device_auth.dart';
import 'package:dr/ui/app_lock_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_device_auth.dart';

void main() {
  late FakeDeviceAuth auth;
  late List<String> channelCalls;
  late int contentTaps;
  late GlobalKey<NavigatorState> navigator;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeDeviceAuth();
    channelCalls = [];
    contentTaps = 0;
    navigator = GlobalKey();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appLockChannel, (call) async {
      channelCalls.add(call.method);
      return null;
    });
  });

  /// The app as `main.dart` puts it together: the lock over everything.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    bool locked = true,
  }) async {
    final c = ProviderContainer(overrides: [
      appLockInitiallyEnabledProvider.overrideWithValue(locked),
      appLockSupportedProvider.overrideWithValue(true),
      deviceAuthProvider.overrideWithValue(auth),
    ]);
    addTearDown(c.dispose);
    // Before the app, as in main(): it must hear "back" first.
    final back = installAppLockBackHandler(c, isAndroid: true);
    addTearDown(() => WidgetsBinding.instance.removeObserver(back));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) => AppLockScope(child: child!),
        routes: {
          '/second': (_) => const Scaffold(body: Text('Zweite Seite')),
        },
        home: Scaffold(
          body: ElevatedButton(
            onPressed: () => contentTaps++,
            child: const Text('Inhalt'),
          ),
        ),
      ),
    ));
    return c;
  }

  testWidgets('the first frame is already covered', (tester) async {
    auth.result = DeviceAuthResult.cancelled;
    await pumpApp(tester);
    expect(find.text('App gesperrt'), findsOneWidget);
  });

  testWidgets('covers the content when locked', (tester) async {
    auth.result = DeviceAuthResult.cancelled;
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Inhalt'), findsNothing);
    await tester.tap(find.text('Inhalt'), warnIfMissed: false);
    expect(contentTaps, 0);
  });

  testWidgets('asks once when shown', (tester) async {
    auth.result = DeviceAuthResult.cancelled;
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(auth.calls, 1);
  });

  testWidgets('the unlock button asks again after a cancel', (tester) async {
    auth.result = DeviceAuthResult.cancelled;
    await pumpApp(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entsperren'));
    await tester.pumpAndSettle();
    expect(auth.calls, 2);
  });

  testWidgets('a success shows the app', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.text('App gesperrt'), findsNothing);
    expect(find.semantics.byLabel('Inhalt'), findsOneWidget);
    await tester.tap(find.text('Inhalt'));
    expect(contentTaps, 1);
  });

  testWidgets('shows why it is still locked', (tester) async {
    auth.result = DeviceAuthResult.lockedOut;
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('Zu viele Versuche. Bitte später erneut versuchen.'),
      findsOneWidget,
    );
  });

  testWidgets('a page opened while locked waits under the lock',
      (tester) async {
    auth.result = DeviceAuthResult.cancelled;
    final c = await pumpApp(tester);
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed('/second');
    await tester.pumpAndSettle();
    expect(find.text('App gesperrt'), findsOneWidget);
    expect(find.semantics.byLabel('Zweite Seite'), findsNothing);

    auth.result = DeviceAuthResult.success;
    await c.read(appLockProvider.notifier).unlock('');
    await tester.pumpAndSettle();
    expect(find.text('Zweite Seite'), findsOneWidget);
  });

  testWidgets('back leaves the app instead of closing pages', (tester) async {
    auth.result = DeviceAuthResult.cancelled;
    await pumpApp(tester);
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed('/second');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isTrue);
    expect(channelCalls, contains('moveTaskToBack'));
  });

  testWidgets('back works as usual when unlocked', (tester) async {
    await pumpApp(tester, locked: false);
    navigator.currentState!.pushNamed('/second');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isFalse);
    expect(channelCalls, isNot(contains('moveTaskToBack')));
  });

  testWidgets('says so when the lock was switched off for lack of one',
      (tester) async {
    auth.result = DeviceAuthResult.notAvailable;
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.text('App gesperrt'), findsNothing);
    expect(
      find.text('Am Gerät ist keine Sperre mehr eingerichtet – '
          'die App-Sperre wurde ausgeschaltet.'),
      findsOneWidget,
    );
  });

  testWidgets('the back gesture is left to Android while locked',
      (tester) async {
    final handlesBack = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handlesBack.add(call.arguments as bool);
        }
        return null;
      },
    );
    auth.result = DeviceAuthResult.cancelled;
    final c = await pumpApp(tester);
    // The app tells Android only once it knows its lifecycle, as on a phone.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed('/second');
    await tester.pumpAndSettle();
    // A page to go back to, but the lock is on: Android takes "back".
    expect(handlesBack.last, isFalse);

    auth.result = DeviceAuthResult.success;
    await c.read(appLockProvider.notifier).unlock('');
    await tester.pumpAndSettle();
    expect(handlesBack.last, isTrue);
  });

  testWidgets('the cover hides the app without a button', (tester) async {
    // On, and unlocked at the start.
    final c = await pumpApp(tester);
    await tester.pumpAndSettle();
    c.read(appLockProvider.notifier).onInactive();
    await tester.pump();
    expect(find.semantics.byLabel('Inhalt'), findsNothing);
    expect(find.text('Entsperren'), findsNothing);
  });
}
