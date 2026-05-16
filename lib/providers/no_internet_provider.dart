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

import 'dart:async';

import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoInternetNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setNoInternet(bool value) {
    final prev = state;
    state = value;
    if (prev == value) return;
    if (value) {
      onGoingOffline();
    } else {
      unawaited(onGoingOnline());
    }
  }

  @protected
  void onGoingOffline() {
    showSnackBar("Keine Verbindung");
    wrapper.logout(hard: false, logoutForcedByServer: true);
  }

  @protected
  Future<void> onGoingOnline() {
    return ref.read(dashboardProvider.notifier).refresh();
  }

  Future<void> refresh() async {
    final noInternet = await wrapper.refreshNoInternet();
    setNoInternet(noInternet);
  }
}

final noInternetProvider =
    NotifierProvider<NoInternetNotifier, bool>(NoInternetNotifier.new);
