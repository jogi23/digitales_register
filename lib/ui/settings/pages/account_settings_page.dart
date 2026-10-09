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

import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/ui/app_lock_settings.dart';
import 'package:dr/ui/settings/widgets/settings_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who is logged in, how long, and what protects the app.
class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  Future<void> _explainStayLoggedIn(BuildContext context) {
    final l = tr(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.settingsStayLoggedIn),
        content: Text(
          '${l.settingsStayLoggedInOffHint}\n\n'
          '${l.settingsStayLoggedInBackgroundHint}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.commonDone),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = tr(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final demo = ref.watch(isDemoProvider);
    return SettingsPageScaffold(
      title: l.settingsCategoryAccount,
      children: [
        if (!demo) ...[
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(l.settingsProfile),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: ref.read(appRouterProvider).showProfile,
          ),
          const AccountSettingsTile(),
        ],
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.login_rounded),
          title: Text(l.settingsStayLoggedIn),
          subtitle: Text(l.settingsStayLoggedInSubtitle),
          value: !settings.noPasswordSaving,
          onChanged: (value) => notifier.setSaveNoPass(!value),
        ),
        // A row of its own: inside the switch's title a screen reader would
        // fold the button into the switch.
        ListTile(
          dense: true,
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(l.settingsMoreInfo),
          onTap: () => _explainStayLoggedIn(context),
        ),
        const AppLockSettingsTiles(),
        // Next to the account switch it is about; the demo has no second
        // account to switch to.
        if (!demo)
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.swap_horiz_rounded),
            title: Text(l.settingsKeepPageOnAccountSwitch),
            subtitle: Text(l.settingsKeepPageOnAccountSwitchSubtitle),
            value: settings.keepPageOnAccountSwitch,
            onChanged: notifier.setKeepPageOnAccountSwitch,
          ),
      ],
    );
  }
}
