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

  setUpAll(() => initializeDateFormatting('de'));
  setUp(() => mockNow = UtcDateTime(2026, 9, 12, 10));
  tearDown(() => mockNow = null);

  testWidgets('a working connection stays a dot, not a message',
      (tester) async {
    await tester.pumpWidget(
      page(ConnectionInfo(lastSuccess: UtcDateTime(2026, 9, 12, 9, 55))),
    );
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.textContaining('Zuletzt aktualisiert'), findsNothing);
  });

  testWidgets('before the first answer the dot is hollow', (tester) async {
    await tester.pumpWidget(page(const ConnectionInfo()));
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  testWidgets('old data names the time it was fetched', (tester) async {
    await tester.pumpWidget(
      page(ConnectionInfo(lastSuccess: UtcDateTime(2026, 9, 12, 9, 30))),
    );
    expect(find.textContaining('Zuletzt aktualisiert'), findsOneWidget);
  });

  testWidgets('no network says so', (tester) async {
    await tester.pumpWidget(
      page(const ConnectionInfo(status: ConnectionStatus.offline)),
    );
    expect(find.text('Keine Verbindung'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });

  testWidgets('an expired session is named as such, not as an outage',
      (tester) async {
    await tester.pumpWidget(
      page(const ConnectionInfo(status: ConnectionStatus.sessionExpired)),
    );
    expect(find.text('Sitzung abgelaufen'), findsOneWidget);
    expect(find.text('Keine Verbindung'), findsNothing);
  });

  testWidgets('tapping offers a new login when the session ran out',
      (tester) async {
    await tester.pumpWidget(
      page(const ConnectionInfo(status: ConnectionStatus.sessionExpired)),
    );
    await tester.tap(find.text('Sitzung abgelaufen'));
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
    expect(find.text('Neu verbinden'), findsOneWidget);
    // Closing leaves the connection alone.
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();
    expect(notifier.reconnects, 0);
  });
}
