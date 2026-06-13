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

// ignore_for_file: avoid_escaping_inner_quotes
import 'package:dr/config.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/login_page_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login = ref.watch(loginProvider);
    final noInternet = ref.watch(noInternetProvider);
    final safeMode = ref.watch(settingsProvider.select((s) => s.noPasswordSaving));
    final notifier = ref.read(loginProvider.notifier);
    return LoginPageContent(
      vm: LoginPageViewModel(
        error: login.errorMsg,
        loading: login.loading,
        safeMode: safeMode,
        noInternet: noInternet,
        servers: schools,
        changePass: login.changePassword,
        mustChangePass: login.mustChangePassword,
        username: login.username,
        url: login.url,
        otherAccounts: login.otherAccounts,
      ),
      onLogin: (user, pass, loginUrl) => notifier.login(user, pass, loginUrl),
      onChangePass: (user, oldPass, newPass, loginUrl) =>
          notifier.changePass(user, oldPass, newPass, loginUrl),
      setSaveNoPass: notifier.saveNoPass,
      onReload: notifier.loadApp,
      onRequestPassReset: notifier.showRequestPassReset,
      onSelectAccount: notifier.selectAccount,
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
  final List<OtherAccount> otherAccounts;

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
