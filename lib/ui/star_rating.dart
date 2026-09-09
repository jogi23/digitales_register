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
import 'package:dr/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A colour the competence stars can be drawn in.
///
/// Two shades per entry rather than one: a tone that is legible on white
/// disappears on a dark background, and the user picks a colour, not a theme.
class StarColor {
  /// Persisted in the settings, so it has to stay stable.
  final String id;

  final Color light;
  final Color dark;

  const StarColor({
    required this.id,
    required this.light,
    required this.dark,
  });

  Color resolve(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// The choices offered in the settings, in the order they are shown.
///
/// A fixed palette rather than a free picker: every entry is picked to stay
/// readable in both themes, which a freely chosen colour would not be.
const starColors = <StarColor>[
  StarColor(
    id: 'amber',
    light: Color(0xFFF9A825),
    dark: Color(0xFFFFD54F),
  ),
  StarColor(
    id: 'orange',
    light: Color(0xFFEF6C00),
    dark: Color(0xFFFFB74D),
  ),
  StarColor(
    id: 'red',
    light: Color(0xFFC62828),
    dark: Color(0xFFEF9A9A),
  ),
  StarColor(
    id: 'pink',
    light: Color(0xFFAD1457),
    dark: Color(0xFFF48FB1),
  ),
  StarColor(
    id: 'purple',
    light: Color(0xFF6A1B9A),
    dark: Color(0xFFCE93D8),
  ),
  StarColor(
    id: 'blue',
    light: Color(0xFF1565C0),
    dark: Color(0xFF90CAF9),
  ),
  StarColor(
    id: 'teal',
    light: Color(0xFF00695C),
    dark: Color(0xFF80CBC4),
  ),
  StarColor(
    id: 'green',
    light: Color(0xFF2E7D32),
    dark: Color(0xFFA5D6A7),
  ),
];

/// The palette entry for a stored id, or null for [accentStarColorId].
///
/// An id that is not in the palette — written by another version — also lands
/// on the accent colour rather than on nothing.
StarColor? starColorById(String id) {
  for (final color in starColors) {
    if (color.id == id) return color;
  }
  return null;
}

/// The colour the stars are currently drawn in.
Color resolveStarColor(BuildContext context, String id) {
  final theme = Theme.of(context);
  return starColorById(id)?.resolve(theme.brightness) ??
      theme.colorScheme.primary;
}

/// A competence rating: [starCount] stars, [filled] of them full.
class StarRow extends ConsumerWidget {
  /// How many stars are filled in.
  final int filled;

  /// Icon size, or null for the surrounding icon theme's.
  final double? size;

  const StarRow({super.key, required this.filled, this.size});

  /// The scale the register grades competences on.
  static const starCount = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        resolveStarColor(context, ref.watch(settingsProvider).starColor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        starCount,
        (n) => Icon(
          n < filled ? Icons.star : Icons.star_border,
          color: color,
          size: size,
        ),
      ),
    );
  }
}
