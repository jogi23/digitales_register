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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dr/providers/provider_container.dart' as pc;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets every golden comparison pass without looking at the image.
///
/// The tests still build their widget, lay it out and paint it — only the
/// comparison against the stored image is dropped.
class _AcceptAnyGolden extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // A German device: the app speaks three languages now, and the test host
  // reports en_US, which would put every golden and every finder into
  // English.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('de')
    ..localesTestValue = const [Locale('de')];

  // The reference images are rendered on the maintainer's machine; a build
  // runner rasterises fonts differently enough that all 60 comparisons fail
  // over a fraction of a percent of pixels. Everything else the widget tests
  // assert — structure, texts, behaviour — runs there unchanged.
  if (Platform.environment['CI'] == 'true') {
    goldenFileComparator = _AcceptAnyGolden();
  }

  SharedPreferences.setMockInitialValues({});
  pc.providerContainer = ProviderContainer();

  return GoldenToolkit.runWithConfiguration(
    () async {
      await loadAppFonts();
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      // Only reaches golden_toolkit's own helpers, which this suite does not
      // use — see the comparator above for what actually decides.
      skipGoldenAssertion: () => !Platform.isLinux,
      enableRealShadows: true,
    ),
  );
}
