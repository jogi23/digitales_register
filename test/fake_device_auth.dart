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

import 'package:dr/services/device_auth.dart';

/// Answers with [result], or waits for [pending] when it is set.
class FakeDeviceAuth implements DeviceAuth {
  FakeDeviceAuth(
      {this.result = DeviceAuthResult.success, this.available = true});

  DeviceAuthResult result;
  bool available;
  Completer<DeviceAuthResult>? pending;
  int calls = 0;

  @override
  Future<bool> canAuthenticate() async => available;

  @override
  Future<DeviceAuthResult> authenticate(String reason) {
    calls++;
    return pending?.future ?? Future.value(result);
  }
}
