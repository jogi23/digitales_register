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

import 'package:dr/debug_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

// The device's own lock — biometrics, falling back to its PIN, pattern or
// password — for the app lock (#114). The app keeps no PIN of its own.

enum DeviceAuthResult { success, cancelled, notAvailable, lockedOut, error }

abstract interface class DeviceAuth {
  /// Whether the device has a lock at all: biometrics or a PIN, pattern or
  /// password.
  Future<bool> canAuthenticate();

  /// Asks for the device's lock, giving [reason]. Never throws.
  Future<DeviceAuthResult> authenticate(String reason);
}

class LocalDeviceAuth implements DeviceAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object catch (e, s) {
      debugLogError('Geräte-Sperre prüfen', e, s);
      return false;
    }
  }

  @override
  Future<DeviceAuthResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        // Not biometrics only (the default): the device PIN is the way in
        // when they fail or are missing.
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return ok ? DeviceAuthResult.success : DeviceAuthResult.cancelled;
    } on LocalAuthException catch (e) {
      return deviceAuthResultFor(e.code);
    } on Object catch (e, s) {
      debugLogError('Geräte-Sperre', e, s);
      return DeviceAuthResult.error;
    }
  }
}

/// What a failure of `local_auth` means for the app lock.
///
/// Only a device without any lock counts as [DeviceAuthResult.notAvailable] —
/// that switches the app lock off. Missing biometrics do not: the device's
/// PIN still opens the app.
@visibleForTesting
DeviceAuthResult deviceAuthResultFor(LocalAuthExceptionCode code) =>
    switch (code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout ||
      LocalAuthExceptionCode.userRequestedFallback ||
      LocalAuthExceptionCode.authInProgress =>
        DeviceAuthResult.cancelled,
      LocalAuthExceptionCode.temporaryLockout ||
      LocalAuthExceptionCode.biometricLockout =>
        DeviceAuthResult.lockedOut,
      LocalAuthExceptionCode.noCredentialsSet => DeviceAuthResult.notAvailable,
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
      LocalAuthExceptionCode.uiUnavailable ||
      LocalAuthExceptionCode.deviceError ||
      LocalAuthExceptionCode.unknownError =>
        DeviceAuthResult.error,
    };

final deviceAuthProvider = Provider<DeviceAuth>((ref) => LocalDeviceAuth());
