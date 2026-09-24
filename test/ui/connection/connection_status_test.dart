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

import 'package:dr/providers/connection_provider.dart';
import 'package:dr/ui/connection_status_button.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _TestConnectionNotifier extends ConnectionNotifier {
  _TestConnectionNotifier(this.initial);
  final ConnectionInfo initial;

  @override
  ConnectionInfo build() => initial;

  int reconnects = 0;

  @override
  Future<void> reconnect() async {
    reconnects++;
  }
}

void main() {
  late _TestConnectionNotifier notifier;

  Widget page(ConnectionInfo info) {
    notifier = _TestConnectionNotifier(info);
    return ProviderScope(
      overrides: [connectionProvider.overrideWith(() => notifier)],
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Merkheft'),
            actions: const [ConnectionStatusButton()],
          ),
        ),
      ),
    );
  }

  /// Words inside the button itself — there should never be any.
  Finder wordsInBar() => find.descendant(
        of: find.byType(ConnectionStatusButton),
        matching: find.byType(Text),
      );

  setUpAll(() => initializeDateFormatting('de'));
  setUp(() => mockNow = UtcDateTime(2026, 9, 12, 10));
  tearDown(() => mockNow = null);

  group('every state is a cloud without words', () {
    testWidgets('connected', (tester) async {
      await tester.pumpWidget(
        page(ConnectionInfo(lastSuccess: UtcDateTime(2026, 9, 12, 9, 55))),
      );
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byTooltip('Verbunden'), findsOneWidget);
      expect(wordsInBar(), findsNothing);
    });

    testWidgets('nothing loaded yet', (tester) async {
      await tester.pumpWidget(page(const ConnectionInfo()));
      expect(find.byIcon(Icons.cloud_queue), findsOneWidget);
      expect(find.byTooltip('Noch nichts geladen'), findsOneWidget);
      expect(wordsInBar(), findsNothing);
    });

    testWidgets('data out of date', (tester) async {
      await tester.pumpWidget(
        page(ConnectionInfo(lastSuccess: UtcDateTime(2026, 9, 12, 9, 30))),
      );
      expect(find.byIcon(Icons.cloud_download), findsOneWidget);
      expect(find.byTooltip('Daten nicht mehr aktuell'), findsOneWidget);
      expect(wordsInBar(), findsNothing);
    });

    testWidgets('offline', (tester) async {
      await tester.pumpWidget(
        page(const ConnectionInfo(status: ConnectionStatus.offline)),
      );
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.byTooltip('Keine Verbindung'), findsOneWidget);
      expect(wordsInBar(), findsNothing);
    });

    testWidgets('session expired', (tester) async {
      await tester.pumpWidget(
        page(const ConnectionInfo(status: ConnectionStatus.sessionExpired)),
      );
      expect(find.byIcon(Icons.cloud), findsOneWidget);
      expect(find.byTooltip('Sitzung abgelaufen'), findsOneWidget);
      expect(wordsInBar(), findsNothing);
    });

    testWidgets('reconnecting', (tester) async {
      await tester.pumpWidget(page(const ConnectionInfo(reconnecting: true)));
      expect(find.byIcon(Icons.cloud_sync), findsOneWidget);
      expect(wordsInBar(), findsNothing);
    });
  });

  testWidgets('fresh data turns stale without the page being rebuilt',
      (tester) async {
    await tester.pumpWidget(
      page(ConnectionInfo(lastSuccess: UtcDateTime(2026, 9, 12, 9, 55))),
    );
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);

    mockNow = UtcDateTime(2026, 9, 12, 10, 11);
    await tester.pump(const Duration(minutes: 1));
    expect(find.byIcon(Icons.cloud_download), findsOneWidget);
  });

  testWidgets('tapping offers a new login when the session ran out',
      (tester) async {
    await tester.pumpWidget(
      page(const ConnectionInfo(status: ConnectionStatus.sessionExpired)),
    );
    await tester.tap(find.byType(ConnectionStatusButton));
    await tester.pumpAndSettle();
    expect(find.text('Verbindung'), findsOneWidget);
    expect(find.text('Neu anmelden'), findsOneWidget);
    await tester.tap(find.text('Neu anmelden'));
    await tester.pumpAndSettle();
    expect(notifier.reconnects, 1);
  });

  testWidgets('tapping a working connection offers a reload', (tester) async {
    await tester.pumpWidget(
      page(ConnectionInfo(lastSuccess: UtcDateTime(2026, 9, 12, 9, 55))),
    );
    await tester.tap(find.byType(ConnectionStatusButton));
    await tester.pumpAndSettle();
    expect(find.text('Verbunden'), findsOneWidget);
    // The wall-clock time as stored, not shifted by the device's zone.
    expect(find.text('Zuletzt aktualisiert: 09:55'), findsOneWidget);
    expect(find.text('Neu verbinden'), findsOneWidget);
    // Closing leaves the connection alone.
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();
    expect(notifier.reconnects, 0);
  });
}
