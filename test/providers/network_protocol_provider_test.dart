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
import 'package:dr/providers/network_protocol_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

NetworkProtocolItem _item() => NetworkProtocolItem((b) => b
  ..address = 'https://school.example/v2/api/x'
  ..response = '{}'
  ..parameters = '{}'
  ..timestamp = DateTime(2026, 10, 8));

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer({required bool debugBuild}) {
    final c = ProviderContainer(overrides: [
      debugBuildProvider.overrideWithValue(debugBuild),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('ignores items while diagnostics are off', () {
    final c = makeContainer(debugBuild: false);
    c.read(networkProtocolProvider.notifier).add(_item());
    expect(c.read(networkProtocolProvider), isEmpty);
  });

  test('records items once diagnostics are on', () {
    final c = makeContainer(debugBuild: false);
    c.read(settingsProvider.notifier).setDiagnosticsEnabled(true);
    c.read(networkProtocolProvider.notifier).add(_item());
    expect(c.read(networkProtocolProvider), hasLength(1));
  });

  test('a debug build records regardless of the switch', () {
    final c = makeContainer(debugBuild: true);
    c.read(networkProtocolProvider.notifier).add(_item());
    expect(c.read(networkProtocolProvider), hasLength(1));
  });
}
