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

/// Ein Eintrag in einer Karte für sich — die Kartenansicht von Klassenbuch,
/// Hausaufgaben, Absenzen und Bewertungen.
///
/// Rahmen, Abstände und Rundung liegen hier, damit die vier Seiten gleich
/// aussehen; was in der Karte steht, bestimmt jede Seite selbst.
class EntryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const EntryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  /// Breiter wird eine Karte nicht: Im Querformat liefe eine Zeile sonst über
  /// den ganzen Bildschirm und wäre kaum zu lesen.
  static const maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 0,
          color: scheme.surfaceContainerLow,
          // Clipped, so a tapped ListTile inside ripples within the corners.
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The tint of every second row in the list view of a page.
Color alternateRowColor(BuildContext context) => Theme.of(context)
    .colorScheme
    .surfaceContainerHighest
    .withValues(alpha: 0.75);
