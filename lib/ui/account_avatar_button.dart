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

import 'dart:io';

import 'package:dr/providers/account_profile_provider.dart';
import 'package:dr/providers/config_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/ui/account_sheet.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The picture of the account currently logged in, or its initials.
class AccountAvatar extends ConsumerWidget {
  final double radius;

  const AccountAvatar({super.key, this.radius = 24});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login = ref.watch(loginProvider);
    final config = ref.watch(configProvider);
    final profiles = ref.watch(accountProfileProvider);

    final displayName = config?.fullName ?? login.username ?? '';
    final key = accountProfileKey(login.username ?? '', login.url ?? '');
    final profile = profiles[key] ?? const AccountProfile();

    final colorScheme = Theme.of(context).colorScheme;
    if (profile.photoPath != null) {
      final file = File(profile.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        accountInitials(profile.alias ?? displayName),
        style: TextStyle(
          // Two letters have to fit whatever size the avatar is.
          fontSize: radius * 0.625,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// The account row in the settings; opens the same card as the app bar avatar.
///
/// Switching accounts used to be reachable only through that avatar, which is
/// easy to miss for something one looks for under settings.
class AccountSettingsTile extends ConsumerWidget {
  const AccountSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login = ref.watch(loginProvider);
    final config = ref.watch(configProvider);
    final profiles = ref.watch(accountProfileProvider);

    final username = login.username ?? '';
    final key = accountProfileKey(username, login.url ?? '');
    final profile = profiles[key] ?? const AccountProfile();
    final name = profile.alias ?? config?.fullName ?? username;

    return ListTile(
      leading: const AccountAvatar(radius: 20),
      title: Text(name),
      subtitle: name != username && username.isNotEmpty ? Text(username) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showAccountSheet(context),
    );
  }
}

/// The avatar in the app bar; opens the account card.
class AccountAvatarButton extends StatelessWidget {
  const AccountAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: GestureDetector(
        onTap: () => showAccountSheet(context),
        child: const AccountAvatar(),
      ),
    );
  }
}


