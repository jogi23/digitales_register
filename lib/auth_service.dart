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

  AuthService(this._apiClient);

  String? user, pass;
  bool demoMode = false;
  String? error;
  late Config config;

  Future<bool> _loggedIn = Future.value(false);
  Future<bool> get loggedIn => _loggedIn;

  VoidCallback? onLogout, onRelogin;

  /// Called after config is parsed during login — the UI can update.
  VoidCallback? onConfigLoaded;

  AddNetworkProtocolItem? onAddProtocolItem;

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
      config = Config(
        (b) => b
          ..autoLogoutSeconds = 300
          ..currentSemesterMaybe = 1
          ..fullName = "Demo User"
          ..imgSource =
              "https://vinzentinum.digitalesregister.it/v2/theme/icons/profile_empty.png"
          ..isStudentOrParent = true
          ..userId = 0,
      );
      onSessionStarted?.call(config);
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
      loggedInCompleter.complete(false);
      log("Error while logging in (login failed)", error: e);
      if (e is TimeoutException || await _refreshNoInternetCheck()) {
        noInternetDuringLogin = true;
      }
      error = "Unknown Error:\n$e";
      return null;
    }
    if (getBool(response["loggedIn"]) ?? false) {
      log("login succeeded");
      lastLoginInteraction = DateTime.now();
      loggedInCompleter.complete(true);
      this.user = user;
      this.pass = pass;
      error = null;
      await _loadConfig().then((_) {
        onSessionStarted?.call(config);
        onConfigLoaded!();
      });
    } else {
      log("login did not succeed");
      loggedInCompleter.complete(false);
      error = "[${response["error"]}] ${response["message"]}";
      switch (getString(response["error"])) {
        case "two_factor_needed":
          final tfaCode = await _request2FA();
          if (tfaCode != null) {
            return login(user, pass, tfaCode, url);
          }
          return;
        case "two_factor_wrong":
          final tfaCode = await _request2FA(wasWrong: true);
          if (tfaCode != null) {
            return login(user, pass, tfaCode, url);
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
      _apiClient.dio.get<dynamic>("${_apiClient.baseAddress}logout");
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
    return showDialog(
      context: navigatorKey!.currentContext!,
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

  Future<void> _loadConfig() async {
    final source =
        (await _apiClient.dio.get<String>(_apiClient.baseAddress)).data;
    config = ConfigParser.parse(source!);
  }
}
