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
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A no-internet notifier that changes nothing else: the real one talks to
/// the server and shows a snack bar.
class _QuietNoInternetNotifier extends NoInternetNotifier {
  _QuietNoInternetNotifier({this.initial = false});
  final bool initial;

  @override
  bool build() => initial;

  @override
  void onGoingOffline() {}

  @override
  Future<void> onGoingOnline() async {}
}

void main() {
  late ProviderContainer container;

  ProviderContainer make({bool offline = false}) => ProviderContainer(
        overrides: [
          noInternetProvider
              .overrideWith(() => _QuietNoInternetNotifier(initial: offline)),
        ],
      );

  setUp(() {
    mockNow = UtcDateTime(2026, 9, 12, 10);
    container = make();
  });

  tearDown(() {
    mockNow = null;
    container.dispose();
  });

  test('starts out connected with nothing loaded', () {
    final state = container.read(connectionProvider);
    expect(state.status, ConnectionStatus.connected);
    expect(state.neverLoaded, isTrue);
    // Nothing was asked for yet, so nothing is out of date either.
    expect(state.isStale, isFalse);
  });

  test('starts out offline when there is no network', () {
    container.dispose();
    container = make(offline: true);
    expect(container.read(connectionProvider).status, ConnectionStatus.offline);
  });

  test('follows the network state', () {
    container.read(connectionProvider);
    container.read(noInternetProvider.notifier).setNoInternet(true);
    expect(container.read(connectionProvider).status, ConnectionStatus.offline);
    container.read(noInternetProvider.notifier).setNoInternet(false);
    expect(
      container.read(connectionProvider).status,
      ConnectionStatus.connected,
    );
  });

  test('an answer from the server counts as connected and fresh', () {
    container.read(connectionProvider.notifier).markSuccess();
    final state = container.read(connectionProvider);
    expect(state.status, ConnectionStatus.connected);
    expect(state.lastSuccess, mockNow);
    expect(state.isStale, isFalse);
  });

  test('data goes stale after a quarter of an hour', () {
    container.read(connectionProvider.notifier).markSuccess();
    mockNow = UtcDateTime(2026, 9, 12, 10, 14);
    expect(container.read(connectionProvider).isStale, isFalse);
    mockNow = UtcDateTime(2026, 9, 12, 10, 16);
    expect(container.read(connectionProvider).isStale, isTrue);
  });

  test('a run of answers does not move the timestamp every time', () {
    final notifier = container.read(connectionProvider.notifier);
    notifier.markSuccess();
    final first = container.read(connectionProvider).lastSuccess;
    mockNow = UtcDateTime(2026, 9, 12, 10, 0, 20);
    notifier.markSuccess();
    expect(container.read(connectionProvider).lastSuccess, first);
    mockNow = UtcDateTime(2026, 9, 12, 10, 1);
    notifier.markSuccess();
    expect(container.read(connectionProvider).lastSuccess, mockNow);
  });

  test('an expired session is told apart from a missing network', () {
    container.read(connectionProvider.notifier).markSessionExpired();
    final state = container.read(connectionProvider);
    expect(state.status, ConnectionStatus.sessionExpired);
    expect(state.hasProblem, isTrue);
  });

  test('no network wins over an expired session', () {
    // Nothing can be reached, so a new login would not help either.
    container.read(noInternetProvider.notifier).setNoInternet(true);
    container.read(connectionProvider.notifier).markSessionExpired();
    expect(container.read(connectionProvider).status, ConnectionStatus.offline);
  });

  test('an answer ends the expired state', () {
    final notifier = container.read(connectionProvider.notifier);
    notifier.markSessionExpired();
    notifier.markSuccess();
    expect(
      container.read(connectionProvider).status,
      ConnectionStatus.connected,
    );
  });
}
