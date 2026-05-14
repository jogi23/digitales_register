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
  final bool changePassword;
  final bool mustChangePassword;
  final List<String> otherAccounts;
  final PassResetState resetPassState;

  const LoginState({
    this.loggedIn = false,
    this.loading = false,
    this.errorMsg,
    this.username,
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
        changePassword: changePassword ?? this.changePassword,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
        otherAccounts: otherAccounts ?? this.otherAccounts,
        resetPassState: resetPassState ?? this.resetPassState,
      );
}

class LoginNotifier extends Notifier<LoginState> {
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

  void setChangePassword({required bool mustChange}) =>
      state = state.copyWith(
        loading: false,
        changePassword: true,
        mustChangePassword: mustChange,
      );

  void showLogin() => state = state.copyWith(changePassword: false);

  void logout({required bool hard}) {
    if (hard) {
      state = state.copyWith(loggedIn: false, username: null);
    }
  }

  void setOtherAccounts(List<String> accounts) =>
      state = state.copyWith(otherAccounts: accounts);

  void updatePassResetState(PassResetState resetPassState) =>
      state = state.copyWith(resetPassState: resetPassState);
}

final loginProvider =
    NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
