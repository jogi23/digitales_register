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
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SidebarContainer extends ConsumerWidget {
  final bool tabletMode;
  final VoidCallback goHome;
  final Pages currentSelected;

  const SidebarContainer({
    super.key,
    required this.tabletMode,
    required this.goHome,
    required this.currentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final login = ref.watch(loginProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    return StoreConnection<AppState, AppActions, (String?, String?)>(
      connect: (state) => (state.config?.fullName, state.config?.imgSource),
      builder: (context, configData, actions) {
        final (fullName, imgSource) = configData;
        return Sidebar(
          currentSelected: currentSelected,
          drawerExpanded: settings.drawerFullyExpanded,
          goHome: goHome,
          onDrawerExpansionChange: settingsNotifier.setDrawerFullyExpanded,
          tabletMode: tabletMode,
          userIcon: imgSource,
          username: fullName ?? login.username,
          showAbsences: actions.routingActions.showAbsences.call,
          showCalendar: actions.routingActions.showCalendar.call,
          showCertificate: actions.routingActions.showCertificate.call,
          showGrades: actions.routingActions.showGrades.call,
          showMessages: actions.routingActions.showMessages.call,
          showSettings: actions.routingActions.showSettings.call,
          otherAccounts: login.otherAccounts,
          selectAccount: actions.loginActions.selectAccount.call,
          addAccount: actions.loginActions.addAccount.call,
          logout: () => actions.loginActions.logout(
            LogoutPayload(
              (b) => b
                ..hard = true
                ..forced = false,
            ),
          ),
          passwordSavingEnabled: !settings.noPasswordSaving,
        );
      },
    );
  }
}
