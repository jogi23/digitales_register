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
import 'package:flutter/material.dart';

GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

void showSnackBar(String message) {
  scaffoldMessengerKey!.currentState!.showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

/// Says briefly that the server cannot be reached.
///
/// Two seconds, then gone: the crossed-out cloud in the title bar keeps
/// saying it for as long as it lasts, so the message only marks the moment.
/// Replaces a message still showing, so repeated attempts do not queue up.
void showNoConnectionToast() {
  scaffoldMessengerKey?.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(trGlobal.noConnection),
        duration: const Duration(seconds: 2),
      ),
    );
}
