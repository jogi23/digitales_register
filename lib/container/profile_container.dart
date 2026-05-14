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

import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/profile_provider.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/ui/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileContainer extends ConsumerWidget {
  const ProfileContainer({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final noInternet = ref.watch(noInternetProvider);
    final router = ref.read(appRouterProvider);
    return Profile(
      profileState: profileState,
      noInternet: noInternet,
      setSendNotificationEmails: (value) =>
          ref.read(profileProvider.notifier).setSendNotificationEmails(value),
      changeEmail: router.showChangeEmail,
      changePass: router.showChangePass,
    );
  }
}
