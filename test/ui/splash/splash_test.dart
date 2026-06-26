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

import 'package:dr/ui/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Widget _build({required bool splash}) {
  return MaterialApp(
    home: SplashScreen(
      splash: splash,
      child: const Scaffold(body: Center(child: Text('child'))),
    ),
  );
}

void main() {
  testWidgets('child is always in tree', (tester) async {
    await tester.pumpWidget(_build(splash: false));
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('child visible when splash:false', (tester) async {
    await tester.pumpWidget(_build(splash: false));
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(opacity.opacity, 0.0);
  });

  testWidgets('overlay visible when splash:true', (tester) async {
    await tester.pumpWidget(_build(splash: true));
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(opacity.opacity, 1.0);
  });

  testWidgets('child still in tree when splash:true', (tester) async {
    await tester.pumpWidget(_build(splash: true));
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('overlay is IgnorePointer', (tester) async {
    await tester.pumpWidget(_build(splash: true));
    // The splash overlay wraps its content in IgnorePointer; at least one with
    // ignoring: true (the AnimatedOpacity parent) must be present.
    final ignorePointers = tester.widgetList<IgnorePointer>(
      find.byType(IgnorePointer),
    );
    expect(
      ignorePointers.any((ip) => ip.ignoring == true),
      isTrue,
    );
  });

  testGoldens('splash visible', (tester) async {
    await tester.pumpWidget(_build(splash: true));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('splash_visible.png'),
    );
  });

  testGoldens('splash hidden', (tester) async {
    await tester.pumpWidget(_build(splash: false));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('splash_hidden.png'),
    );
  });
}
