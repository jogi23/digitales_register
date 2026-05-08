// Copyright (C) 2021 Michael Debertol
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

import 'package:dr/api_client.dart';
import 'package:dr/app_state.dart';
import 'package:dr/auth_service.dart';
import 'package:dr/demo.dart';
import 'package:dr/main.dart';
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

  SessionManager(this._apiClient, this._authService);

  bool safeMode = false;
  bool noInternet = false;
  DateTime lastInteraction = DateTime.now();

  DateTime? _serverLogoutTime;
  final _loginMutex = Mutex();
  DateTime? _lastUnexpectedLogout;

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
        DateTime.now().add(Duration(seconds: config.autoLogoutSeconds));
    _updateLogout();
  }

  Future<bool> ensureLoggedIn({
    bool isRetryAfterUnexpectedLogout = false,
  }) async {
    await _loginMutex.acquire();
    try {
      if (_serverLogoutTime != null &&
          DateTime.now().isAfter(_serverLogoutTime!)) {
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
              await actions.noInternet(true);
            } else {
              _authService.logout(hard: true, logoutForcedByServer: true);
            }
            return false;
          } else {
            _authService.onRelogin!();
          }
        } else {
          if (noInternet) {
            await actions.noInternet(true);
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
  }) async {
    if (_authService.demoMode) {
      return getDemoResponse(url, args);
    }
    assert(!url.startsWith("/"));

    if (!await ensureLoggedIn(
      isRetryAfterUnexpectedLogout: isRetryAfterUnexpectedLogout,
    )) {
      log("returning null for request to $url, user is not logged in");
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
      await _handleError(e);
      _authService.onAddProtocolItem!(NetworkProtocolItem((b) => b
        ..address = _apiClient.baseAddress + url
        ..response = stringifyMaybeJson(responseData)
        ..parameters = stringifyMaybeJson(args)));
      return null;
    }
    _authService.onAddProtocolItem!(NetworkProtocolItem((b) => b
      ..address = _apiClient.baseAddress + url
      ..response = stringifyMaybeJson(responseData)
      ..parameters = stringifyMaybeJson(args)));

    // returned if we were logged out (there should be whitespace at both ends, but the editor is removing it):
    //	<script type="text/javascript">
    //window.location = "https://vinzentinum.digitalesregister.it/v2/login";
    //</script>

    if (responseData is String &&
        RegExp(r'^[\s\n]*<script type="text/javascript">\n?\s*window\.location = "https://.+\.digitalesregister.it/v2/login";\n?\s*</script>[\s\n]*$')
            .hasMatch(responseData)) {
      if (isRetryAfterUnexpectedLogout) {
        log("retrying the request was unsuccessful, we seem to be still logged out.");
        throw UnexpectedLogoutException();
      }

      return send(
        url,
        args: args,
        method: method,
        isRetryAfterUnexpectedLogout: true,
      );
    }
    return responseData;
  }

  Future<void> _handleError(Exception e) async {
    log("Error while sending request", error: e);
    if (e is TimeoutException || await refreshNoInternet()) {
      noInternet = true;
      _authService.forceLoggedOut();
      await actions.noInternet(true);
      _authService.error = "Keine Internetverbindung";
    } else {
      _authService.error = e.toString();
    }
  }

  Future<void> _updateLogout() async {
    if (!await _authService.loggedIn) return;
    if (_authService.demoMode) return;
    if (_serverLogoutTime != null &&
        DateTime.now()
            .add(const Duration(seconds: 25))
            .isAfter(_serverLogoutTime!)) {
      final result = getMap(
        await send(
          "api/auth/extendSession",
          args: <String, Object?>{
            "lastAction": lastInteraction.millisecondsSinceEpoch ~/ 1000,
          },
        ),
      );
      if (result == null) {
        _authService.logout(hard: safeMode, logoutForcedByServer: true);
        return;
      }
      if (result["forceLogout"] == true) {
        _authService.logout(hard: safeMode, logoutForcedByServer: true);
        return;
      } else {
        _serverLogoutTime = DateTime.fromMillisecondsSinceEpoch(
            (result["newExpiration"] as int) * 1000);
      }
    }
    Future.delayed(const Duration(seconds: 5), _updateLogout);
  }
}
