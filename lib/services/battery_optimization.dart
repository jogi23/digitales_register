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

import 'package:dr/debug_log.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Whether Android holds back the background check of the notifications
// (#318): see MainActivity.kt. The app only asks and opens the settings page;
// it never requests the exemption itself, which Google Play restricts.

const batteryChannel = MethodChannel('dr/battery');

/// Whether Android leaves the app out of the battery optimization. Null where
/// that cannot be told: off Android, or when the question failed.
Future<bool?> isIgnoringBatteryOptimizations({bool? isAndroid}) =>
    _invoke<bool>('isIgnoring', isAndroid: isAndroid);

/// Opens the system page where the exemption can be given.
Future<void> openBatteryOptimizationSettings({bool? isAndroid}) =>
    _invoke<void>('openSettings', isAndroid: isAndroid);

Future<T?> _invoke<T>(String method, {bool? isAndroid}) async {
  if (!(isAndroid ?? Platform.isAndroid)) return null;
  try {
    return await batteryChannel.invokeMethod<T>(method);
  } on Object catch (e, s) {
    debugLogError('Akku-Optimierung $method', e, s);
    return null;
  }
}

/// The answer to [isIgnoringBatteryOptimizations]; invalidate it to ask again.
final batteryOptimizationProvider = FutureProvider.autoDispose<bool?>(
  (ref) => isIgnoringBatteryOptimizations(),
);
