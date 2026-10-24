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
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in the browser or the app that handles it.
Future<bool> openExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// A row that opens a page in the app ([internal], arrow), leaves the app
/// (external symbol) or just does something ([action], no symbol).
class LinkTile extends StatelessWidget {
  const LinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.internal = false,
    this.action = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool internal;
  final bool action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: action
          ? null
          : internal
              ? const Icon(Icons.chevron_right_rounded)
              : Icon(
                  Icons.open_in_new_rounded,
                  semanticLabel: tr(context).linkOpensOutside,
                ),
      onTap: onTap,
    );
  }
}
