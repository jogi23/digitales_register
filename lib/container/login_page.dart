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

import 'package:dr/actions/app_actions.dart';
import 'package:dr/actions/login_actions.dart';
import 'package:dr/app_state.dart';
// ignore_for_file: avoid_escaping_inner_quotes
import 'package:dr/config.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/login_page_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login = ref.watch(loginProvider);
    final noInternet = ref.watch(noInternetProvider);
    final safeMode = ref.watch(settingsProvider.select((s) => s.noPasswordSaving));
    return StoreConnection<AppState, AppActions, String?>(
      connect: (state) => state.url,
      builder: (context, url, actions) {
        final vm = LoginPageViewModel(
          error: login.errorMsg,
          loading: login.loading,
          safeMode: safeMode,
          noInternet: noInternet,
          servers: schools,
          changePass: login.changePassword,
          mustChangePass: login.mustChangePassword,
          username: login.username,
          url: url,
          otherAccounts: login.otherAccounts,
        );
        return LoginPageContent(
          vm: vm,
          onLogin: (user, pass, loginUrl) {
            actions.loginActions.login(
              LoginPayload(
                (b) => b
                  ..user = user
                  ..pass = pass
                  ..url = loginUrl
                  ..fromStorage = false,
              ),
            );
          },
          onChangePass: (user, oldPass, newPass, loginUrl) {
            actions.loginActions.changePass(
              ChangePassPayload(
                (b) => b
                  ..user = user
                  ..url = loginUrl
                  ..oldPass = oldPass
                  ..newPass = newPass,
              ),
            );
          },
          setSaveNoPass: actions.settingsActions.saveNoPass.call,
          onReload: actions.load.call,
          onRequestPassReset: actions.routingActions.showRequestPassReset.call,
          onSelectAccount: actions.loginActions.selectAccount.call,
        );
      },
    );
  }
}

typedef LoginCallback = void Function(String user, String pass, String url);
typedef SetSafeModeCallback = void Function(bool safeMode);

class LoginPageViewModel {
  final String? error;
  final String? username;
  final String? url;
  final bool loading, safeMode, noInternet, changePass, mustChangePass;
  final Map<String, String> servers;
  final List<String> otherAccounts;

  const LoginPageViewModel({
    required this.error,
    required this.loading,
    required this.safeMode,
    required this.noInternet,
    required this.servers,
    required this.changePass,
    required this.mustChangePass,
    required this.username,
    required this.url,
    required this.otherAccounts,
  });
}
