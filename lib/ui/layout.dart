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
import 'package:responsive_scaffold/responsive_scaffold.dart'
    show compactHeightBreakpoint;

/// Where the system puts its bars, and how much room the frame leaves.
///
/// Every screen needs the same two answers, so they are given once here.
extension SystemInsets on BuildContext {
  /// Padding content has to keep free so no system bar covers it.
  ///
  /// Upright the navigation bar rests at the bottom, sideways at one side —
  /// screens that only kept the bottom clear ran underneath it.
  ///
  /// The top is left out on purpose: an app bar already covers it, and the
  /// pages this is used on all have one.
  EdgeInsets get systemInsets {
    final padding = MediaQuery.viewPaddingOf(this);
    return EdgeInsets.only(
      left: padding.left,
      right: padding.right,
      bottom: padding.bottom,
    );
  }

  /// Just the bottom part of [systemInsets], for a plain spacer.
  double get systemBottomInset => MediaQuery.viewPaddingOf(this).bottom;

  /// Whether the frame is too short to spend the usual room on headers and
  /// padding — a phone held sideways.
  bool get isCompactHeight =>
      MediaQuery.sizeOf(this).height < compactHeightBreakpoint;

  /// A vertical gap, halved where height is scarce.
  double compactGap(double normal) => isCompactHeight ? normal / 2 : normal;
}
