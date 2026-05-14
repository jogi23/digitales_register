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

import 'package:dr/actions/app_actions.dart';
import 'package:dr/actions/login_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/config_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/app_router.dart';
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
    final config = ref.watch(configProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final router = ref.read(appRouterProvider);
    return StoreConnection<AppState, AppActions, Object>(
      connect: (_) => const Object(),
      builder: (context, _, actions) {
        return Sidebar(
          currentSelected: currentSelected,
          drawerExpanded: settings.drawerFullyExpanded,
          goHome: goHome,
          onDrawerExpansionChange: settingsNotifier.setDrawerFullyExpanded,
          tabletMode: tabletMode,
          userIcon: config?.imgSource,
          username: config?.fullName ?? login.username,
          showAbsences: router.showAbsences,
          showCalendar: router.showCalendar,
          showCertificate: router.showCertificate,
          showGrades: router.showGrades,
          showMessages: router.showMessages,
          showSettings: router.showSettings,
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
