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

import 'package:flutter/material.dart';

/// The background of every page in dark mode when it is not tinted.
const neutralDarkBackground = Color(0xFF121212);

/// The app's theme, built from the accent colour picked in the settings.
///
/// Material 3 tints the page background with that colour. With
/// [accentBackground] off the pages sit on plain white — or plain dark in
/// dark mode — while buttons, headings and markers keep the accent colour.
ThemeData appTheme(
  Brightness brightness,
  Color seedColor, {
  bool accentBackground = true,
}) {
  final scheme =
      ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    // Scaffold, app bar and canvas all take their colour from `surface`, so
    // replacing that one colour reaches every page.
    colorScheme: accentBackground
        ? scheme
        : scheme.copyWith(
            surface: brightness == Brightness.dark
                ? neutralDarkBackground
                : Colors.white,
          ),
  );
}
