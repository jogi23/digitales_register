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

import 'package:dr/app_links.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/services/app_sharing.dart';
import 'package:dr/ui/about_page.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/ui/link_tile.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';

/// The menu's "Über": spreading the word, other apps, and the way on to
/// the about page.
class AboutHubPage extends StatelessWidget {
  const AboutHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.menuAbout)),
      body: ListView(
        padding: context.systemInsets,
        children: [
          LinkTile(
            icon: Icons.star_rounded,
            title: l.menuRate,
            onTap: openPlayStoreListing,
          ),
          LinkTile(
            icon: Icons.share_rounded,
            title: l.menuShare,
            action: true,
            onTap: () => shareApp(context),
          ),
          LinkTile(
            icon: Icons.apps_rounded,
            title: l.menuOtherApps,
            subtitle: l.aboutOtherAppsSubtitle,
            onTap: () => openExternal(AppLinks.otherApps),
          ),
          LinkTile(
            icon: Icons.info_rounded,
            title: l.aboutTitle,
            subtitle: l.aboutVersion(appVersion),
            internal: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
        ],
      ),
    );
  }
}
