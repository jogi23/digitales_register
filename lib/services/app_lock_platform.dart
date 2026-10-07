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
import 'dart:io';

import 'package:dr/debug_log.dart';
import 'package:dr/providers/app_lock_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// What the app lock (#114) needs from the Android activity: no preview of
// the app in the recent apps while the lock is on, and leaving the app when
// "back" is pressed on the lock screen.

const appLockChannel = MethodChannel('dr/app_lock');

/// Hides the app's preview in the recent apps — from Android 13 on; before
/// that the lock screen covers the app as it leaves. True when Android does
/// it.
Future<bool> setRecentsHidden(bool hidden, {bool? isAndroid}) async =>
    await _invoke<bool>('setRecentsHidden', hidden, isAndroid: isAndroid) ??
    false;

/// Sends the app to the background, as "back" on the home screen does.
Future<void> moveTaskToBack({bool? isAndroid}) =>
    _invoke('moveTaskToBack', null, isAndroid: isAndroid);

Future<T?> _invoke<T>(String method, Object? arguments,
    {bool? isAndroid}) async {
  if (!(isAndroid ?? Platform.isAndroid)) return null;
  try {
    return await appLockChannel.invokeMethod<T>(method, arguments);
  } on Object catch (e, s) {
    debugLogError('App-Sperre $method', e, s);
    return null;
  }
}

/// Keeps the recents preview hidden while the lock is on, from now on.
void keepRecentsInSync(ProviderContainer container, {bool? isAndroid}) {
  if (!(isAndroid ?? Platform.isAndroid)) return;
  container.listen<bool>(
    settingsProvider.select((s) => s.appLockEnabled),
    (_, enabled) async {
      final byAndroid = await setRecentsHidden(enabled, isAndroid: isAndroid);
      container.read(recentsHiddenByAndroidProvider.notifier).state = byAndroid;
    },
    fireImmediately: true,
  );
}
