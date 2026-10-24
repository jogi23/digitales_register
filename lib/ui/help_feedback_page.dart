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
import 'package:dr/ui/help_page.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/ui/link_tile.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// FAQ and the ways to reach the developer: mail, ideas, bug reports.
class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: ListView(
        padding: context.systemInsets,
        children: [
          LinkTile(
            icon: Icons.quiz_rounded,
            title: l.helpOfflineFaq,
            internal: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
          LinkTile(
            icon: Icons.email_rounded,
            title: l.helpWriteEmail,
            subtitle: AppLinks.contactEmail,
            onTap: () => launchUrl(AppLinks.feedbackMail(appVersion)),
          ),
          LinkTile(
            icon: Icons.lightbulb_rounded,
            title: l.helpSuggestFeature,
            onTap: () => openExternal(AppLinks.suggestFeature),
          ),
          LinkTile(
            icon: Icons.bug_report_rounded,
            title: l.helpReportBug,
            onTap: () => openExternal(AppLinks.reportBug),
          ),
        ],
      ),
    );
  }
}
