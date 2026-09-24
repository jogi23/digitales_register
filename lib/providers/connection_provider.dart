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

import 'package:dr/debug_log.dart';
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart' show now;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why the app is or is not talking to the server.
///
/// Two things can stand in the way, and they need different answers: without
/// a network nothing can be done but wait, while an expired session needs a
/// new login. Telling them apart is the point of this type.
enum ConnectionStatus {
  /// The server answered, and nothing says it stopped.
  connected,

  /// The device cannot reach the server at all.
  offline,

  /// The network is there, but the server no longer knows this session.
  sessionExpired,
}

/// What the app knows about its link to the server.
@immutable
class ConnectionInfo {
  final ConnectionStatus status;

  /// When the server last answered, null while nothing has been loaded yet.
  final UtcDateTime? lastSuccess;

  /// Whether a reconnect attempt is running.
  final bool reconnecting;

  const ConnectionInfo({
    this.status = ConnectionStatus.connected,
    this.lastSuccess,
    this.reconnecting = false,
  });

  /// After this long the shown data is old enough to say so.
  static const staleAfter = Duration(minutes: 15);

  /// Whether what is shown was fetched long enough ago to say so.
  bool get isStale {
    final last = lastSuccess;
    if (last == null) return false;
    return now.difference(last) > staleAfter;
  }

  /// Whether the server has not answered once yet.
  ///
  /// Not the same as stale: nothing may have been asked for yet. Worth
  /// showing all the same — a screen full of saved data looks no different
  /// from a fresh one.
  bool get neverLoaded => lastSuccess == null;

  /// Whether something is in the way of talking to the server.
  bool get hasProblem => status != ConnectionStatus.connected;

  ConnectionInfo copyWith({
    ConnectionStatus? status,
    UtcDateTime? lastSuccess,
    bool? reconnecting,
  }) =>
      ConnectionInfo(
        status: status ?? this.status,
        lastSuccess: lastSuccess ?? this.lastSuccess,
        reconnecting: reconnecting ?? this.reconnecting,
      );

  @override
  bool operator ==(Object other) =>
      other is ConnectionInfo &&
      other.status == status &&
      other.lastSuccess == lastSuccess &&
      other.reconnecting == reconnecting;

  @override
  int get hashCode => Object.hash(status, lastSuccess, reconnecting);
}

class ConnectionNotifier extends Notifier<ConnectionInfo> {
  @override
  ConnectionInfo build() {
    // Whether the device has a network is already tracked; this provider
    // adds the second reason and the freshness on top of it.
    ref.listen<bool>(
        noInternetProvider, (_, offline) => _applyOffline(offline));
    return ConnectionInfo(
      status: ref.read(noInternetProvider)
          ? ConnectionStatus.offline
          : ConnectionStatus.connected,
    );
  }

  void _applyOffline(bool offline) {
    debugLog(LogCategory.session, offline ? 'Offline' : 'Wieder online');
    if (offline) {
      state = state.copyWith(status: ConnectionStatus.offline);
    } else if (state.status == ConnectionStatus.offline) {
      state = state.copyWith(status: ConnectionStatus.connected);
    }
  }

  /// How often a plain run of successful requests moves the timestamp.
  ///
  /// Every request reports success, and every report would rebuild whatever
  /// shows the state. The display is coarse anyway.
  static const _timestampResolution = Duration(seconds: 30);

  /// The server answered — whatever was in the way is gone.
  void markSuccess() {
    final answeredAt = now;
    final last = state.lastSuccess;
    if (state.status == ConnectionStatus.connected &&
        last != null &&
        answeredAt.difference(last) < _timestampResolution) {
      return;
    }
    state = ConnectionInfo(
      lastSuccess: answeredAt,
      reconnecting: state.reconnecting,
    );
  }

  /// The network is there, but the session is not.
  void markSessionExpired() {
    if (state.status == ConnectionStatus.offline) return;
    if (state.status != ConnectionStatus.sessionExpired) {
      debugLog(LogCategory.session, 'Anzeige: Sitzung abgelaufen');
    }
    state = state.copyWith(status: ConnectionStatus.sessionExpired);
  }

  /// Tries to get back to a working connection.
  ///
  /// First the network, then the session: a new login is pointless while
  /// nothing can be reached, and reloading is pointless while the server has
  /// forgotten the session. If the session cannot be renewed with what is
  /// stored, the login form is the only way on.
  Future<void> reconnect() async {
    if (state.reconnecting) return;
    state = state.copyWith(reconnecting: true);
    debugLog(LogCategory.session, 'Verbindung wiederherstellen');
    try {
      await ref.read(noInternetProvider.notifier).refresh();
      if (ref.read(noInternetProvider)) {
        state = state.copyWith(status: ConnectionStatus.offline);
        return;
      }
      if (!await wrapper.ensureLoggedIn()) {
        // A login that fails for want of a network is not an expired
        // session: sending the reader to the login form there asked for a
        // password they did not need, on a page they could not leave.
        if (ref.read(noInternetProvider) || wrapper.noInternet) {
          debugLog(LogCategory.session, 'Wiederherstellen: kein Netz');
          state = state.copyWith(status: ConnectionStatus.offline);
          return;
        }
        debugLog(
          LogCategory.session,
          'Wiederherstellen: Anmeldung nötig, Formular',
        );
        state = state.copyWith(status: ConnectionStatus.sessionExpired);
        ref.read(appRouterProvider).showLogin();
        return;
      }
      await ref.read(dashboardProvider.notifier).refresh();
      markSuccess();
    } finally {
      state = state.copyWith(reconnecting: false);
    }
  }
}

final connectionProvider = NotifierProvider<ConnectionNotifier, ConnectionInfo>(
  ConnectionNotifier.new,
);
