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

import 'package:dr/l10n/l10n.dart';
import 'package:dr/util.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';

/// The accent colours to choose from, named in the reader's language.
List<({String label, Color color})> _accentColors(BuildContext context) => [
      (label: tr(context).colorOrange, color: const Color(0xFFFF5722)),
      (label: tr(context).colorRed, color: const Color(0xFFF44336)),
      (label: tr(context).colorPink, color: const Color(0xFFE91E63)),
      (label: tr(context).colorPurple, color: const Color(0xFF9C27B0)),
      (label: tr(context).colorIndigo, color: const Color(0xFF3F51B5)),
      (label: tr(context).colorBlue, color: const Color(0xFF2196F3)),
      (label: tr(context).colorTeal, color: const Color(0xFF009688)),
      (label: tr(context).colorGreen, color: const Color(0xFF4CAF50)),
      (label: tr(context).colorBrown, color: const Color(0xFF795548)),
      (label: tr(context).colorGrey, color: const Color(0xFF607D8B)),
    ];

/// Circles in the palette of accent colours; the chosen one carries a check
/// and a ring, so the choice does not rest on colour alone.
class AccentColorPicker extends StatelessWidget {
  const AccentColorPicker({super.key});

  static const _target = 48.0;
  static const _circle = 36.0;

  @override
  Widget build(BuildContext context) {
    final currentSeed = DynamicTheme.of(context)!.seedColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context).settingsAccentColor,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Wrap(
            children: [
              for (final entry in _accentColors(context))
                _Swatch(
                  label: entry.label,
                  color: entry.color,
                  selected: entry.color.toARGB32() == currentSeed.toARGB32(),
                  onTap: () =>
                      DynamicTheme.of(context)!.setSeedColor(entry.color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkResponse(
          onTap: onTap,
          radius: AccentColorPicker._target / 2,
          child: SizedBox.square(
            dimension: AccentColorPicker._target,
            child: Center(
              child: Container(
                width: AccentColorPicker._circle,
                height: AccentColorPicker._circle,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                ),
                child: selected
                    ? Icon(Icons.check, size: 18, color: readableOn(color))
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
