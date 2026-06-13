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
import 'package:dr/ui/account_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountAvatarButton extends ConsumerWidget {
  const AccountAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login = ref.watch(loginProvider);
    final config = ref.watch(configProvider);
    final profiles = ref.watch(accountProfileProvider);

    final username = config?.fullName ?? login.username ?? '';
    final url = login.url ?? '';
    final key = accountProfileKey(login.username ?? '', url);
    final profile = profiles[key] ?? const AccountProfile();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: GestureDetector(
        onTap: () => showAccountBottomSheet(context),
        child: _buildAvatar(context, profile, username),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    AccountProfile profile,
    String displayName,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    if (profile.photoPath != null) {
      final file = File(profile.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 24,
          backgroundImage: FileImage(file),
        );
      }
    }
    final initials = _initials(profile.alias ?? displayName);
    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, trimmed.length.clamp(0, 3)).toUpperCase();
}
