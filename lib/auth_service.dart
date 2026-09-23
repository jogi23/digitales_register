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

import 'package:dr/api_client.dart';
import 'package:dr/app_state.dart';
import 'package:dr/config_parser.dart';
import 'package:dr/demo.dart' as demo;
import 'package:dr/main.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';

typedef AddNetworkProtocolItem = void Function(NetworkProtocolItem item);

/// Handles login, logout, credential storage, and config loading.
///
/// Communicates with the server only for auth endpoints. All other requests
/// go through [SessionManager.send].
class AuthService {
  final ApiClient _apiClient;
  final Future<int> Function() _getDemoUserId;

  AuthService(this._apiClient, {Future<int> Function()? getDemoUserId})
      : _getDemoUserId = getDemoUserId ?? demo.getDemoUserId;

  String? user, pass;
  bool demoMode = false;
  String? error;

  /// The account's configuration; null until a login has loaded it.
  Config? config;

  Future<bool> _loggedIn = Future.value(false);
  Future<bool> get loggedIn => _loggedIn;

  VoidCallback? onLogout, onRelogin;

  /// Called after config is parsed during login — the UI can update.
  VoidCallback? onConfigLoaded;

  AddNetworkProtocolItem? onAddProtocolItem;

  /// Whether the app has signed in on this instance and handed over its
  /// callbacks — successfully or not, a start without a network counts.
  ///
  /// Until then the app's own sign-in is still on its way: after an account
  /// switch, and at every start from storage, the stored Merkheft shows
  /// before the login goes out. A request in that gap must not sign in by
  /// itself: it would do so without the callbacks, and race the app's login
  /// for the session cookie.
  bool get appHasSignedIn => onLogout != null;

  /// Hook called by [Wrapper] to allow [SessionManager] to start the session
  /// timer once config is available.
  void Function(Config)? onSessionStarted;

  /// Forces [loggedIn] to resolve as false (e.g. after a network error).
  void forceLoggedOut() {
    _loggedIn = Future.value(false);
  }

  Future<dynamic> login(
    String? user,
    String? pass,
    String? tfaCode,
    String? url, {
    bool allowInteractive2fa = true,
    VoidCallback? logout,
    VoidCallback? configLoaded,
    VoidCallback? relogin,
    AddNetworkProtocolItem? addProtocolItem,
  }) async {
    if (isDemoUser(url: url, username: user)) {
      demoMode = true;
      _loggedIn = Future.value(true);
      this.user = user;
      this.pass = pass;
      final demoUserId = await _getDemoUserId();
      final demoConfig = Config(
        (b) => b
          ..autoLogoutSeconds = 300
          ..currentSemesterMaybe = 1
          ..fullName = "Demo User"
          ..imgSource =
              "https://vinzentinum.digitalesregister.it/v2/theme/icons/profile_empty.png"
          ..isStudentOrParent = true
          ..userId = demoUserId,
      );
      config = demoConfig;
      onSessionStarted?.call(demoConfig);
      configLoaded?.call();
      return;
    } else {
      demoMode = false;
    }

    if (logout != null) {
      onLogout = logout;
    } else {
      assert(onLogout != null);
    }
    if (configLoaded != null) {
      onConfigLoaded = configLoaded;
    } else {
      assert(onConfigLoaded != null);
    }
    if (relogin != null) {
      onRelogin = relogin;
    } else {
      assert(onRelogin != null);
    }
    if (addProtocolItem != null) {
      onAddProtocolItem = addProtocolItem;
    } else {
      assert(onAddProtocolItem != null);
    }

    _apiClient.url = url;
    final loggedInCompleter = Completer<bool>();
    _loggedIn = loggedInCompleter.future;
    Map response;
    _apiClient.clearCookies();
    try {
      response = getMap(
        (await _apiClient.dio.post<dynamic>(
          _apiClient.loginAddress,
          data: {
            "username": user,
            "password": pass,
            if (tfaCode != null) "two_factor": tfaCode,
          },
        ))
            .data,
      )!;
    } catch (e) {
      await _failLogin(loggedInCompleter, e);
      return null;
    }
    if (getBool(response["loggedIn"]) ?? false) {
      final Config loadedConfig;
      try {
        loadedConfig = await _loadConfig();
      } catch (e) {
        // The server said yes but did not hand over the account's home page.
        // Counting that as logged in left the app without a user id, and the
        // parse error ended it.
        await _failLogin(loggedInCompleter, e);
        return null;
      }
      log("login succeeded");
      lastLoginInteraction = DateTime.now();
      config = loadedConfig;
      loggedInCompleter.complete(true);
      this.user = user;
      this.pass = pass;
      error = null;
      onSessionStarted?.call(loadedConfig);
      onConfigLoaded!();
    } else {
      log("login did not succeed");
      loggedInCompleter.complete(false);
      error = "[${response["error"]}] ${response["message"]}";
      switch (getString(response["error"])) {
        case "two_factor_needed":
          if (!allowInteractive2fa) {
            log("2FA needed, but this login attempt is non-interactive.");
            return response;
          }
          final tfaCode = await _request2FA();
          if (tfaCode != null) {
            return login(
              user,
              pass,
              tfaCode,
              url,
              allowInteractive2fa: allowInteractive2fa,
            );
          }
          return;
        case "two_factor_wrong":
          if (!allowInteractive2fa) {
            log("2FA code wrong, but this login attempt is non-interactive.");
            return response;
          }
          final tfaCode = await _request2FA(wasWrong: true);
          if (tfaCode != null) {
            return login(
              user,
              pass,
              tfaCode,
              url,
              allowInteractive2fa: allowInteractive2fa,
            );
          }
          return;
      }
    }
    return response;
  }

  /// Tracks the last user interaction for auto-logout purposes.
  ///
  /// Exposed here so [SessionManager] can delegate to [Wrapper.lastInteraction].
  DateTime lastLoginInteraction = DateTime.now();

  /// Temporary flag set during login when no internet is detected.
  bool noInternetDuringLogin = false;

  Future<void> _failLogin(Completer<bool> loggedIn, Object e) async {
    loggedIn.complete(false);
    log("Error while logging in (login failed)", error: e);
    // A page that arrived but was the wrong one says nothing about the
    // connection.
    if (e is TimeoutException ||
        (e is! ConfigParseException && await _refreshNoInternetCheck())) {
      noInternetDuringLogin = true;
    }
    error = "Unknown Error:\n$e";
  }

  Future<bool> _refreshNoInternetCheck() async {
    final address = _apiClient.url != null
        ? _apiClient.baseAddress
        : "https://digitalesregister.it";
    return cannotConnectTo(address);
  }

  Future<dynamic> changePass(
      String url, String user, String oldPass, String newPass) async {
    _apiClient.url = url;
    Map response;
    _apiClient.clearCookies();
    try {
      response = getMap((await _apiClient.dio.post<dynamic>(
        "${_apiClient.baseAddress}api/auth/setNewPassword",
        data: {
          "username": user,
          "oldPassword": oldPass,
          "newPassword": newPass,
        },
      ))
          .data)!;
    } catch (e) {
      _loggedIn = Future.value(false);
      log("Failed to change pass", error: e);
      error = "Unknown Error:\n$e";
      return null;
    }
    if (response["error"] != null) {
      error = "[${response["error"]}] ${response["message"]}";
    } else {
      _loggedIn = Future.value(false);
      this.user = user;
      pass = newPass;
      error = null;
    }
    return response;
  }

  void logout({required bool hard, bool logoutForcedByServer = false}) {
    if (!logoutForcedByServer && _apiClient.url != null) {
      // Best-effort: local state clears below regardless of whether the
      // server ever hears about it, so a failure here (e.g. a session that
      // never actually logged in, or the network being down) must not
      // become an unhandled error.
      unawaited(() async {
        try {
          await _apiClient.dio.get<dynamic>("${_apiClient.baseAddress}logout");
        } on Exception {
          // Ignored, see above.
        }
      }());
    }
    if (hard) {
      if (logoutForcedByServer) {
        onLogout!();
      }
      _apiClient.url = null;
      user = pass = null;
    }
    _loggedIn = Future.value(false);
    _apiClient.clearCookies();
  }

  Future<String?> _request2FA({bool wasWrong = false}) {
    final context = navigatorKey?.currentContext;
    if (context == null) {
      log("2FA dialog requested without UI context; aborting.");
      return Future.value(null);
    }
    return showDialog(
      context: context,
      builder: (context) {
        final textInputController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => InfoDialog(
            title: Text(
                wasWrong ? "Ungültiger Code" : "Zweiter Faktor wird benötigt"),
            content: TextField(
              controller: textInputController,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Abbrechen"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  textInputController.value.text,
                ),
                child: const Text("Bestätigen"),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Throws [ConfigParseException] if the server answers with a page other
  /// than the account's home page.
  Future<Config> _loadConfig() async {
    final source =
        (await _apiClient.dio.get<String>(_apiClient.baseAddress)).data;
    return ConfigParser.parse(source ?? "");
  }
}
