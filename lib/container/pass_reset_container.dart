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
import 'package:dr/app_state.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/ui/pass_reset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PassResetContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resetPass = ref.watch(loginProvider.select((s) => s.resetPassState));
    return StoreConnection<AppState, AppActions, Object>(
      connect: (_) => const Object(),
      builder: (context, _, actions) {
        return PassReset(
          message: resetPass.message,
          failure: resetPass.failure,
          resetPass: actions.loginActions.resetPass.call,
          onClose: actions.load.call,
        );
      },
    );
  }
}
