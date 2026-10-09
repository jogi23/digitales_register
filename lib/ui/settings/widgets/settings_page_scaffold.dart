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

import 'package:dr/ui/connection_status_button.dart';
import 'package:dr/ui/layout.dart';
import 'package:flutter/material.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

/// Frame shared by the hub and every settings page: app bar with the
/// connection status, and a list that keeps clear of the system bars.
///
/// The [root] is a page of the menu and carries its menu button; the others
/// are pushed on top and carry the back arrow instead.
class SettingsPageScaffold extends StatelessWidget {
  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.root = false,
    this.cacheExtent,
  });

  final String title;
  final List<Widget> children;
  final bool root;

  /// How far beyond the screen rows are built; a page that scrolls to one of
  /// its rows needs it built.
  final double? cacheExtent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: root
          ? ResponsiveAppBar(
              title: Text(title),
              actions: const [ConnectionStatusButton()],
            )
          : AppBar(
              title: Text(title),
              actions: const [ConnectionStatusButton()],
            ),
      body: ListView(
        cacheExtent: cacheExtent,
        padding: context.systemInsets,
        children: children,
      ),
    );
  }
}
