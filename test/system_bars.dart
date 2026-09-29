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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// How the phone is held, which decides where its navigation bar sits.
enum Holding {
  /// The navigation bar at the bottom.
  upright,

  /// The navigation bar at the side — three-button navigation moves it
  /// there when the phone is turned.
  sideways,
}

/// Gives the test view the size and system bars of a phone held [holding].
///
/// The app draws edge to edge, behind the bars: whatever does not keep clear
/// of them on its own ends up underneath (#308).
void holdPhone(WidgetTester tester, Holding holding) {
  final upright = holding == Holding.upright;
  final bars = upright
      ? const FakeViewPadding(top: 24, bottom: 48)
      : const FakeViewPadding(top: 24, right: 48);
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = upright ? const Size(412, 915) : const Size(915, 412)
    ..viewPadding = bars
    ..padding = bars;
  addTearDown(tester.view.reset);
}

/// Scrolls [scrollable] — the first one on the page if left out — to its
/// very end.
///
/// A lazy list only learns its full length while it builds, so the jump is
/// repeated until the end stops moving.
Future<void> scrollToEnd(WidgetTester tester, [Finder? scrollable]) async {
  final position = tester
      .state<ScrollableState>(scrollable ?? find.byType(Scrollable).first)
      .position;
  for (var i = 0; i < 10; i++) {
    final end = position.maxScrollExtent;
    position.jumpTo(end);
    await tester.pumpAndSettle();
    if (position.maxScrollExtent == end) break;
  }
}

/// Fails if what [finder] finds reaches under one of the system bars set up
/// by [holdPhone].
void expectClearOfSystemBars(WidgetTester tester, Finder finder) {
  final view = tester.view;
  final size = view.physicalSize / view.devicePixelRatio;
  final bars = view.viewPadding;
  final ratio = view.devicePixelRatio;
  final rect = tester.getRect(finder);
  expect(
    rect.bottom,
    lessThanOrEqualTo(size.height - bars.bottom / ratio),
    reason: '$rect runs under the navigation bar below',
  );
  expect(
    rect.right,
    lessThanOrEqualTo(size.width - bars.right / ratio),
    reason: '$rect runs under the navigation bar at the side',
  );
  expect(
    rect.left,
    greaterThanOrEqualTo(bars.left / ratio),
    reason: '$rect runs under a bar on the left',
  );
}
