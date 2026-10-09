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

import 'package:dr/app_state.dart';
import 'package:dr/debug_log.dart';
import 'package:dr/providers/network_protocol_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/diagnostics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('turning the switch on and off starts and stops recording', () async {
    final log = DebugLog(enabled: false);
    final c = ProviderContainer(overrides: [
      debugBuildProvider.overrideWithValue(false),
    ]);
    addTearDown(c.dispose);
    keepDiagnosticsInSync(c, log: log, debugBuild: false);
    final settings = c.read(settingsProvider.notifier);

    settings.setDiagnosticsEnabled(true);
    expect(log.enabled, isTrue);
    log.add(LogCategory.start, 'aufgezeichnet');
    c.read(networkProtocolProvider.notifier).add(NetworkProtocolItem((b) => b
      ..address = 'a'
      ..response = '{}'
      ..parameters = '{}'
      ..timestamp = DateTime(2026, 10, 8)));
    expect(log.entries, hasLength(1));
    expect(c.read(networkProtocolProvider), hasLength(1));

    settings.setDiagnosticsEnabled(false);
    await pumpEventQueue();
    expect(log.enabled, isFalse);
    expect(log.entries, isEmpty);
    expect(c.read(networkProtocolProvider), isEmpty);

    log.add(LogCategory.start, 'danach');
    expect(log.entries, isEmpty);
  });

  test('a debug build keeps recording when the switch goes off', () async {
    final log = DebugLog();
    final c = ProviderContainer();
    addTearDown(c.dispose);
    keepDiagnosticsInSync(c, log: log, debugBuild: true);
    final settings = c.read(settingsProvider.notifier);

    settings.setDiagnosticsEnabled(true);
    log.add(LogCategory.start, 'eins');
    settings.setDiagnosticsEnabled(false);
    await pumpEventQueue();

    expect(log.enabled, isTrue);
    expect(log.entries, hasLength(1));
  });
}
