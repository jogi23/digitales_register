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
import 'package:dr/ui/layout.dart';
import 'package:flutter/material.dart';

/// The common questions, answered in the app so they work offline.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    final faq = [
      (l.faqLoginQ, l.faqLoginA),
      (l.faqNotificationsQ, l.faqNotificationsA),
      (l.faqProfilesQ, l.faqProfilesA),
      (l.faqHomeworkQ, l.faqHomeworkA),
      (l.faqAppLockQ, l.faqAppLockA),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.helpOfflineFaq)),
      body: ListView(
        padding: context.systemInsets,
        children: [
          for (final (question, answer) in faq)
            ExpansionTile(
              title: Text(question),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [Text(answer)],
            ),
        ],
      ),
    );
  }
}
