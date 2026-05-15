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

import 'package:dio/dio.dart';
import 'package:dr/api_client.dart';
import 'package:dr/app_state.dart';
import 'package:dr/auth_service.dart';
import 'package:dr/config_parser.dart';
import 'package:dr/session_manager.dart';
import 'package:flutter/foundation.dart';

export 'package:dr/auth_service.dart' show AddNetworkProtocolItem;
// Re-export so existing `import wrapper.dart` callers still resolve the type.
export 'package:dr/session_manager.dart' show UnexpectedLogoutException;

/// Facade that composes [ApiClient], [AuthService], and [SessionManager].
///
/// The public API is intentionally identical to the old monolithic Wrapper so
/// that all middleware and test code continues to work without changes.
class Wrapper {
  late final ApiClient _apiClient;
  late final AuthService _auth;
  late final SessionManager _session;

  Wrapper() {
    _apiClient = ApiClient();
    _auth = AuthService(_apiClient);
    _session = SessionManager(_apiClient, _auth);
    // Wire session start hook: when login completes and config is available,
    // SessionManager starts the auto-logout loop.
    _auth.onSessionStarted = _session.startSession;
  }

  // ── URL ──────────────────────────────────────────────────────────────────

  String? get url => _apiClient.url;

  set url(String? value) {
    if (value != _apiClient.url) {
      // URL change means a different school/server → force logout.
      _auth.logout(hard: true);
    }
    _apiClient.url = value;
  }

  String get baseAddress => _apiClient.baseAddress;
  String get loginAddress => _apiClient.loginAddress;

  /// Raw [Dio] instance — used by middleware for direct file downloads.
  Dio get dio => _apiClient.dio;

  // ── Auth state ────────────────────────────────────────────────────────────

  String? get user => _auth.user;
  String? get pass => _auth.pass;
  Config get config => _auth.config;
  String? get error => _auth.error;
  Future<bool> get loggedIn => _auth.loggedIn;

  // ── Session state ─────────────────────────────────────────────────────────

  bool get noInternet => _session.noInternet;
  set noInternet(bool value) => _session.noInternet = value;

  bool get safeMode => _session.safeMode;
  set safeMode(bool value) => _session.safeMode = value;

  DateTime get lastInteraction => _session.lastInteraction;

  // ── Methods ───────────────────────────────────────────────────────────────

  void interaction() => _session.interaction();

  Future<bool> refreshNoInternet() => _session.refreshNoInternet();

  Future<bool> ensureLoggedIn({
    bool isRetryAfterUnexpectedLogout = false,
  }) =>
      _session.ensureLoggedIn(
          isRetryAfterUnexpectedLogout: isRetryAfterUnexpectedLogout);

  Future<dynamic> send(
    String url, {
    Map<String, Object?> args = const <String, Object?>{},
    String method = "POST",
    bool isRetryAfterUnexpectedLogout = false,
  }) =>
      _session.send(url,
          args: args,
          method: method,
          isRetryAfterUnexpectedLogout: isRetryAfterUnexpectedLogout);

  Future<dynamic> login(
    String? user,
    String? pass,
    String? tfaCode,
    String? url, {
    VoidCallback? logout,
    VoidCallback? configLoaded,
    VoidCallback? relogin,
    AddNetworkProtocolItem? addProtocolItem,
  }) =>
      _auth.login(
        user,
        pass,
        tfaCode,
        url,
        logout: logout,
        configLoaded: configLoaded,
        relogin: relogin,
        addProtocolItem: addProtocolItem,
      );

  Future<dynamic> changePass(
          String url, String user, String oldPass, String newPass) =>
      _auth.changePass(url, user, oldPass, newPass);

  void logout({required bool hard, bool logoutForcedByServer = false}) =>
      _auth.logout(hard: hard, logoutForcedByServer: logoutForcedByServer);

  // ── Backward-compatible static helper ────────────────────────────────────

  /// Delegates to [ConfigParser.parse]. Kept for test backward compatibility.
  static Config parseConfig(String source) => ConfigParser.parse(source);
}
