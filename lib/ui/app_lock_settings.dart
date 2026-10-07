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

import 'package:dr/app_state.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/app_lock_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/device_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Lock app" and how soon it locks again, for the settings page (#114).
/// Both ways, the switch only moves once the device's lock was passed.
class AppLockSettingsTiles extends ConsumerWidget {
  const AppLockSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appLockSupportedProvider)) return const SizedBox.shrink();
    final (enabled, grace) = ref.watch(
      settingsProvider.select((s) => (s.appLockEnabled, s.appLockGraceMinutes)),
    );
    final l = tr(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile.adaptive(
          title: Text(l.settingsAppLock),
          subtitle: Text(l.settingsAppLockSubtitle),
          value: enabled,
          onChanged: (value) => _switch(context, ref, value),
        ),
        if (enabled)
          ListTile(
            title: Text(l.settingsAppLockGrace),
            trailing: DropdownButton<int>(
              value: grace,
              onChanged: (value) {
                if (value == null) return;
                ref
                    .read(settingsProvider.notifier)
                    .setAppLockGraceMinutes(value);
              },
              items: [
                for (final minutes in allowedAppLockGraceMinutes)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(
                      minutes == 0
                          ? l.settingsAppLockGraceNow
                          : l.settingsAppLockGraceMinutes(minutes),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _switch(BuildContext context, WidgetRef ref, bool on) async {
    final l = tr(context);
    if (on && !await ref.read(deviceAuthProvider).canAuthenticate()) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l.settingsAppLockNoDeviceLock),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
      return;
    }
    if (!await ref.read(appLockProvider.notifier).confirm(l.appLockReason)) {
      return;
    }
    ref.read(settingsProvider.notifier).setAppLockEnabled(on);
  }
}
