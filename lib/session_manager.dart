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
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:dr/api_client.dart';
import 'package:dr/app_state.dart';
import 'package:dr/auth_service.dart';
import 'package:dr/demo.dart';
import 'package:dr/util.dart';
import 'package:mutex/mutex.dart';

// Declared here (instead of wrapper.dart) to avoid a circular import.
class UnexpectedLogoutException implements Exception {}

/// Manages session lifetime, auto-logout, and authenticated HTTP requests.
///
/// All middleware HTTP calls go through [send]. Authentication is enforced
/// by [ensureLoggedIn] before each request.
class SessionManager {
  final ApiClient _apiClient;
  final AuthService _authService;

  SessionManager(
    this._apiClient,
    this._authService, {
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final DateTime Function() _clock;

  bool safeMode = false;
  bool noInternet = false;
  DateTime lastInteraction = DateTime.now();

  void Function(bool)? onNoInternet;

  /// Called when a request could not be sent although the network is there:
  /// the server-side session is gone.
  ///
  /// Without this the app simply showed whatever it had loaded before, and a
  /// dead session looked like a school with nothing to report.
  void Function()? onSessionExpired;

  /// Called whenever the server actually answered, so the app can say how
  /// fresh what it shows is.
  void Function()? onRequestSucceeded;

  /// When the session runs out, by the server's clock.
  DateTime? _serverLogoutTime;

  /// How far the server's clock is ahead of the device's. The server hands
  /// out expiration times by its own clock; comparing them with a device
  /// clock that is off ended sessions too early or kept dead ones.
  Duration _clockOffset = Duration.zero;

  /// The next session check. Every login starts the checks anew; without
  /// cancelling, each one left its own chain of checks behind.
  Timer? _sessionTimer;

  final _loginMutex = Mutex();
  DateTime? _lastUnexpectedLogout;

  DateTime get _serverNow => _clock().add(_clockOffset);

  void interaction() {
    lastInteraction = DateTime.now();
  }

  Future<bool> refreshNoInternet() async {
    final address = _apiClient.url != null
        ? _apiClient.baseAddress
        : "https://digitalesregister.it";
    return noInternet = await cannotConnectTo(address);
  }

  /// Called by [Wrapper] when login completes and config is available.
  void startSession(Config config) {
    _serverLogoutTime =
        _serverNow.add(Duration(seconds: config.autoLogoutSeconds));
    _checkSession();
  }

  Future<bool> ensureLoggedIn({
    bool isRetryAfterUnexpectedLogout = false,
  }) async {
    await _loginMutex.acquire();
    try {
      if (_serverLogoutTime != null &&
          _serverNow.isAfter(_serverLogoutTime!)) {
        _authService.forceLoggedOut();
      }
      if (isRetryAfterUnexpectedLogout) {
        if (_lastUnexpectedLogout
                ?.add(const Duration(minutes: 1))
                .isAfter(DateTime.now()) ??
            false) {
          log("unexpected logout: not trying to relogin, last relogin attempt was less than a minute ago.");
          log("  retrying just the request (we might have logged in in the meantime, as requests are running in parallel).");
        } else {
          log("unexpected logout: trying to relogin and retrying the request after that.");
          _authService.forceLoggedOut();
          _lastUnexpectedLogout = DateTime.now();
        }
      }

      if (!await _authService.loggedIn) {
        if (_authService.user != null && _authService.pass != null) {
          await _authService.login(
              _authService.user, _authService.pass, null, _apiClient.url);
          if (!await _authService.loggedIn) {
            if (noInternet) {
              onNoInternet?.call(true);
            } else {
              _authService.logout(hard: true, logoutForcedByServer: true);
            }
            return false;
          } else {
            _authService.onRelogin!();
          }
        } else {
          if (noInternet) {
            onNoInternet?.call(true);
          }
          return false;
        }
      }
    } finally {
      _loginMutex.release();
    }
    return true;
  }

  Future<dynamic> send(
    String url, {
    Map<String, Object?> args = const <String, Object?>{},
    String method = "POST",
    bool isRetryAfterUnexpectedLogout = false,
    void Function(Object error)? onError,
  }) async {
    if (_authService.demoMode) {
      final dynamic response = await getDemoResponse(url, args);
      // The demo answers the way the server would. Without reporting it the
      // connection display waited forever for a first answer.
      if (response != null) onRequestSucceeded?.call();
      return response;
    }
    assert(!url.startsWith("/"));

    if (!await ensureLoggedIn(
      isRetryAfterUnexpectedLogout: isRetryAfterUnexpectedLogout,
    )) {
      log("returning null for request to $url, user is not logged in");
      // Not being logged in with a working network is a session that ran
      // out, not an outage: it needs a new login, not another try.
      if (!noInternet) onSessionExpired?.call();
      // A retry that cannot sign in again is where the first failure ends.
      if (isRetryAfterUnexpectedLogout) {
        onError?.call(UnexpectedLogoutException());
      }
      return null;
    }

    dynamic responseData;
    try {
      final response = await (method == "POST"
          ? _apiClient.dio.post<dynamic>(
              _apiClient.baseAddress + url,
              data: args,
            )
          : method == "GET"
              ? _apiClient.dio.get<dynamic>(
                  _apiClient.baseAddress + url,
                )
              : throw Exception(
                  "invalid method: $method; expected POST or GET"));
      responseData = response.data;
    } on Exception catch (e) {
      // 401 is the server saying the session is gone, the same as the login
      // redirect below. Treated like any other error it left every page
      // empty without a word, and the connection display never noticed.
      if (e is DioException && e.response?.statusCode == 401) {
        _record(url, args, e.response?.data, error: e);
        if (isRetryAfterUnexpectedLogout) {
          log("retrying the request was unsuccessful, the server still answers 401.");
          _authService.error = e.toString();
          onSessionExpired?.call();
          onError?.call(e);
          return null;
        }
        return send(
          url,
          args: args,
          method: method,
          isRetryAfterUnexpectedLogout: true,
          onError: onError,
        );
      }
      await _handleError(e);
      _record(url, args, responseData, error: e);
      onError?.call(e);
      return null;
    }
    _record(url, args, responseData);

    // returned if we were logged out (there should be whitespace at both ends, but the editor is removing it):
    //	<script type="text/javascript">
    //window.location = "https://vinzentinum.digitalesregister.it/v2/login";
    //</script>

    if (responseData is String &&
        RegExp(r'^[\s\n]*<script type="text/javascript">\n?\s*window\.location = "https://.+\.digitalesregister.it/v2/login";\n?\s*</script>[\s\n]*$')
            .hasMatch(responseData)) {
      if (isRetryAfterUnexpectedLogout) {
        log("retrying the request was unsuccessful, we seem to be still logged out.");
        onSessionExpired?.call();
        throw UnexpectedLogoutException();
      }

      return send(
        url,
        args: args,
        method: method,
        isRetryAfterUnexpectedLogout: true,
      );
    }
    onRequestSucceeded?.call();
    return responseData;
  }

  /// Writes one request to the network log. Both call sites used to build
  /// the item themselves, and the failing one quietly left out the reason.
  void _record(
    String url,
    Map<String, Object?> args,
    dynamic responseData, {
    Object? error,
  }) {
    _authService.onAddProtocolItem!(NetworkProtocolItem((b) => b
      ..address = _apiClient.baseAddress + url
      ..response = stringifyMaybeJson(responseData)
      ..parameters = stringifyMaybeJson(args)
      ..timestamp = DateTime.now()
      ..error = error?.toString()));
  }

  Future<void> _handleError(Exception e) async {
    log("Error while sending request", error: e);
    if (e is TimeoutException || await refreshNoInternet()) {
      noInternet = true;
      _authService.forceLoggedOut();
      onNoInternet?.call(true);
      _authService.error = "Keine Internetverbindung";
    } else {
      _authService.error = e.toString();
    }
  }

  /// Extends the session shortly before it runs out and checks again in a
  /// few seconds, for as long as the account stays logged in.
  Future<void> _checkSession() async {
    _sessionTimer?.cancel();
    try {
      if (!await _authService.loggedIn) return;
      if (_authService.demoMode) return;
      if (_serverLogoutTime != null &&
          _serverNow
              .add(const Duration(seconds: 25))
              .isAfter(_serverLogoutTime!)) {
        await _extendSession();
      }
    } on Exception catch (e) {
      // Runs from a timer nobody awaits: an error here used to end the app.
      // The next round checks the login again.
      log("Error while extending the session", error: e);
    }
    // Checks may overlap while one waits for the server; whichever finishes
    // last leaves the only timer.
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(seconds: 5), _checkSession);
  }

  Future<void> _extendSession() async {
    final result = getMap(
      await send(
        "api/auth/extendSession",
        args: <String, Object?>{
          "lastAction":
              lastInteraction.add(_clockOffset).millisecondsSinceEpoch ~/ 1000,
        },
      ),
    );
    if (result == null) {
      // Without network there is no answer either, and no reason to log out:
      // the next request signs in again once the network is back.
      if (!noInternet) {
        _authService.logout(hard: safeMode, logoutForcedByServer: true);
      }
      return;
    }
    final serverTime = result["serverTime"];
    if (serverTime is int) {
      _clockOffset = DateTime.fromMillisecondsSinceEpoch(serverTime * 1000)
          .difference(_clock());
    }
    final newExpiration = result["newExpiration"];
    if (result["forceLogout"] == true) {
      _authService.logout(hard: safeMode, logoutForcedByServer: true);
    } else if (result["noSession"] == true) {
      // The server no longer knows the session but did not ask to log out:
      // the next request signs in again with the stored login.
      _authService.forceLoggedOut();
    } else if (newExpiration is int) {
      _serverLogoutTime =
          DateTime.fromMillisecondsSinceEpoch(newExpiration * 1000);
    }
  }
}
