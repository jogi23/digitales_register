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

import 'package:dr/providers/no_internet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mirrors the Redux `AppState.isDemo` flag so Riverpod widgets can react
/// without depending on the Redux store.
///
/// Updated by the login middleware whenever the logged-in user changes.
final isDemoProvider = StateProvider<bool>((ref) => false);

// Sentinel for nullable copyWith parameters.
const _s = Object();

class PassResetState {
  final String? message;
  final bool failure;
  final String? token;
  final String? email;
  final String? username;

  const PassResetState({
    this.message,
    this.failure = false,
    this.token,
    this.email,
    this.username,
  });

  PassResetState copyWith({
    Object? message = _s,
    bool? failure,
    Object? token = _s,
    Object? email = _s,
    Object? username = _s,
  }) =>
      PassResetState(
        message: message == _s ? this.message : message as String?,
        failure: failure ?? this.failure,
        token: token == _s ? this.token : token as String?,
        email: email == _s ? this.email : email as String?,
        username: username == _s ? this.username : username as String?,
      );
}

class LoginState {
  final bool loggedIn;
  final bool loading;
  final String? errorMsg;
  final String? username;
  final String? url;
  final bool changePassword;
  final bool mustChangePassword;
  final List<String> otherAccounts;
  final PassResetState resetPassState;

  const LoginState({
    this.loggedIn = false,
    this.loading = false,
    this.errorMsg,
    this.username,
    this.url,
    this.changePassword = false,
    this.mustChangePassword = true,
    this.otherAccounts = const [],
    this.resetPassState = const PassResetState(),
  });

  LoginState copyWith({
    bool? loggedIn,
    bool? loading,
    Object? errorMsg = _s,
    Object? username = _s,
    Object? url = _s,
    bool? changePassword,
    bool? mustChangePassword,
    List<String>? otherAccounts,
    PassResetState? resetPassState,
  }) =>
      LoginState(
        loggedIn: loggedIn ?? this.loggedIn,
        loading: loading ?? this.loading,
        errorMsg: errorMsg == _s ? this.errorMsg : errorMsg as String?,
        username: username == _s ? this.username : username as String?,
        url: url == _s ? this.url : url as String?,
        changePassword: changePassword ?? this.changePassword,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
        otherAccounts: otherAccounts ?? this.otherAccounts,
        resetPassState: resetPassState ?? this.resetPassState,
      );
}

class LoginNotifier extends Notifier<LoginState> {
  // Redux dispatch bridges — set via initReduxDispatchers during app/test init.
  void Function()? _addAccountDispatch;
  void Function(int)? _selectAccountDispatch;
  void Function({required bool hard, bool forced})? _logoutDispatch;
  void Function(String user, String pass, String url)? _loginDispatch;
  void Function(String user, String oldPass, String newPass, String url)? _changePassDispatch;
  void Function(bool)? _saveNoPassDispatch;
  void Function()? _loadDispatch;
  void Function(String url)? _showRequestPassResetDispatch;
  void Function(String newPass)? _resetPassDispatch;
  void Function(String user, String email)? _requestPassResetDispatch;

  /// Wires up Redux dispatchers for actions that still require middleware side
  /// effects. Called once by [RegisterApp.initState] so both the real app and
  /// tests pick up the correct (store-connected) actions.
  void initReduxDispatchers({
    required void Function() addAccount,
    required void Function(int) selectAccount,
    required void Function({required bool hard, bool forced}) logout,
    required void Function(String user, String pass, String url) login,
    required void Function(String user, String oldPass, String newPass, String url) changePass,
    required void Function(bool) saveNoPass,
    required void Function() load,
    required void Function(String url) showRequestPassReset,
    required void Function(String newPass) resetPass,
    required void Function(String user, String email) requestPassReset,
  }) {
    _addAccountDispatch = addAccount;
    _selectAccountDispatch = selectAccount;
    _logoutDispatch = logout;
    _loginDispatch = login;
    _changePassDispatch = changePass;
    _saveNoPassDispatch = saveNoPass;
    _loadDispatch = load;
    _showRequestPassResetDispatch = showRequestPassReset;
    _resetPassDispatch = resetPass;
    _requestPassResetDispatch = requestPassReset;
  }

  @override
  LoginState build() => const LoginState();

  void reset() => state = const LoginState();

  void setLoggingIn() =>
      state = state.copyWith(loading: true, errorMsg: null);

  void setLoggedIn({required String username, bool keepLoading = false}) =>
      state = state.copyWith(
        loggedIn: true,
        loading: keepLoading,
        errorMsg: null,
        username: username,
      );

  void setLoginFailed({required String cause, String? username}) =>
      state = state.copyWith(
        loggedIn: false,
        loading: false,
        errorMsg: cause,
        username: username,
      );

  void setUsername(String username) =>
      state = state.copyWith(username: username);

  void setUrl(String? url) => state = state.copyWith(url: url);

  void setChangePassword({required bool mustChange}) =>
      state = state.copyWith(
        loading: false,
        changePassword: true,
        mustChangePassword: mustChange,
      );

  void showLogin() => state = state.copyWith(changePassword: false);

  // Called by middleware (dual-write) to apply logout state to Riverpod.
  void logout({required bool hard}) {
    if (hard) {
      state = state.copyWith(loggedIn: false, username: null);
    }
  }

  void setOtherAccounts(List<String> accounts) =>
      state = state.copyWith(otherAccounts: accounts);

  void updatePassResetState(PassResetState resetPassState) =>
      state = state.copyWith(resetPassState: resetPassState);

  // ─── UI-facing actions ────────────────────────────────────────────────────

  void addAccount() => _addAccountDispatch?.call();
  void selectAccount(int index) => _selectAccountDispatch?.call(index);
  void requestLogout({required bool hard, bool forced = false}) =>
      _logoutDispatch?.call(hard: hard, forced: forced);
  void login(String user, String pass, String url) =>
      _loginDispatch?.call(user, pass, url);
  void changePass(String user, String oldPass, String newPass, String url) =>
      _changePassDispatch?.call(user, oldPass, newPass, url);
  void saveNoPass(bool value) => _saveNoPassDispatch?.call(value);
  void loadApp() => _loadDispatch?.call();
  void showRequestPassReset(String url) =>
      _showRequestPassResetDispatch?.call(url);
  void refreshNoInternet() =>
      unawaited(ref.read(noInternetProvider.notifier).refresh());
  void resetPass(String newPass) => _resetPassDispatch?.call(newPass);
  void requestPassReset(String user, String email) =>
      _requestPassResetDispatch?.call(user, email);
}

final loginProvider =
    NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
