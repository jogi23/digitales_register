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

import 'dart:async';

import 'package:dr/providers/connection_provider.dart';
import 'package:dr/ui/pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestConnectionNotifier extends ConnectionNotifier {
  _TestConnectionNotifier(this.initial, {this.reconnectsTo});
  final ConnectionInfo initial;

  /// The state a reconnect ends in; null leaves it where it was.
  final ConnectionStatus? reconnectsTo;
  int reconnects = 0;

  @override
  ConnectionInfo build() => initial;

  @override
  Future<void> reconnect() async {
    reconnects++;
    if (reconnectsTo case final status?) {
      state = state.copyWith(status: status);
    }
  }
}

void main() {
  late int refreshes;
  late _TestConnectionNotifier connection;

  setUp(() => refreshes = 0);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Future<void> Function()? onRefresh,
    ConnectionInfo info = const ConnectionInfo(),
    ConnectionStatus? reconnectsTo,
  }) async {
    connection = _TestConnectionNotifier(info, reconnectsTo: reconnectsTo);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionProvider.overrideWith(() => connection)],
        child: MaterialApp(
          home: Scaffold(
            body: PullToRefresh(
              onRefresh: () {
                refreshes++;
                return onRefresh?.call() ?? Future<void>.value();
              },
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Pulls down from [from] and lets the indicator start its refresh.
  Future<void> pull(WidgetTester tester, Finder from) async {
    await tester.fling(from, const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a page that does not scroll can be pulled', (tester) async {
    // A spinner or "no connection" fills the page without scrolling, and
    // such pages used to ignore the pull.
    await pump(tester, const Center(child: Text('Keine Daten')));
    await pull(tester, find.text('Keine Daten'));
    expect(refreshes, 1);
  });

  testWidgets('a list can be pulled from its top', (tester) async {
    await pump(
      tester,
      ListView(
        children: [for (var i = 0; i < 40; i++) ListTile(title: Text('$i'))],
      ),
    );
    await pull(tester, find.text('0'));
    expect(refreshes, 1);
  });

  testWidgets('the spinner stays until the reload is done', (tester) async {
    final loading = Completer<void>();
    await pump(
      tester,
      const Center(child: Text('Inhalt')),
      onRefresh: () => loading.future,
    );
    await pull(tester, find.text('Inhalt'));
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    loading.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('swiping sideways between pages does not reload',
      (tester) async {
    await pump(
      tester,
      PageView(
        children: const [
          Center(child: Text('Woche 1')),
          Center(child: Text('Woche 2')),
        ],
      ),
    );
    await tester.fling(find.text('Woche 1'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(refreshes, 0);
  });

  testWidgets('pulling down on a sideways page still reloads', (tester) async {
    await pump(
      tester,
      PageView(
        children: const [
          Center(child: Text('Woche 1')),
          Center(child: Text('Woche 2')),
        ],
      ),
    );
    await pull(tester, find.text('Woche 1'));
    expect(refreshes, 1);
  });

  testWidgets('offline, the connection comes back before the reload',
      (tester) async {
    await pump(
      tester,
      const Center(child: Text('Inhalt')),
      info: const ConnectionInfo(status: ConnectionStatus.offline),
      reconnectsTo: ConnectionStatus.connected,
    );
    await pull(tester, find.text('Inhalt'));
    expect(connection.reconnects, 1);
    expect(refreshes, 1);
  });

  testWidgets('while still offline nothing is reloaded', (tester) async {
    await pump(
      tester,
      const Center(child: Text('Inhalt')),
      info: const ConnectionInfo(status: ConnectionStatus.offline),
    );
    await pull(tester, find.text('Inhalt'));
    expect(connection.reconnects, 1);
    expect(refreshes, 0);
  });
}
