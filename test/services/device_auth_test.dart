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

import 'package:dr/services/device_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  group('deviceAuthResultFor', () {
    test('the user or the system breaking off counts as cancelled', () {
      for (final code in [
        LocalAuthExceptionCode.userCanceled,
        LocalAuthExceptionCode.systemCanceled,
        LocalAuthExceptionCode.timeout,
        LocalAuthExceptionCode.userRequestedFallback,
        LocalAuthExceptionCode.authInProgress,
      ]) {
        expect(deviceAuthResultFor(code), DeviceAuthResult.cancelled,
            reason: code.name);
      }
    });

    test('too many attempts count as locked out', () {
      expect(deviceAuthResultFor(LocalAuthExceptionCode.temporaryLockout),
          DeviceAuthResult.lockedOut);
      expect(deviceAuthResultFor(LocalAuthExceptionCode.biometricLockout),
          DeviceAuthResult.lockedOut);
    });

    test('only a device without any lock counts as not available', () {
      expect(deviceAuthResultFor(LocalAuthExceptionCode.noCredentialsSet),
          DeviceAuthResult.notAvailable);
      // The device PIN still works without biometrics: switching the lock
      // off for these would be wrong.
      for (final code in [
        LocalAuthExceptionCode.noBiometricsEnrolled,
        LocalAuthExceptionCode.noBiometricHardware,
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable,
      ]) {
        expect(deviceAuthResultFor(code), DeviceAuthResult.error,
            reason: code.name);
      }
    });

    test('every code has a result', () {
      for (final code in LocalAuthExceptionCode.values) {
        expect(deviceAuthResultFor(code), isA<DeviceAuthResult>());
      }
    });
  });
}
