// Copyright (C) 2021 Michael Debertol
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

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/ui/about_hub_page.dart';
import 'package:dr/ui/help_feedback_page.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.drawerExpanded,
    required this.onDrawerExpansionChange,
    required this.tabletMode,
    required this.goHome,
    required this.currentSelected,
    required this.showGrades,
    required this.showAbsences,
    required this.showCalendar,
    required this.showCertificate,
    required this.showClassbook,
    required this.showHomeworkOverview,
    required this.showCourseContent,
    required this.showMessages,
    required this.showSettings,
    required this.logout,
  });

  final DrawerCallback onDrawerExpansionChange;
  final VoidCallback goHome,
      showGrades,
      showAbsences,
      showCalendar,
      showCertificate,
      showClassbook,
      showHomeworkOverview,
      showCourseContent,
      showMessages,
      showSettings,
      logout;
  final bool tabletMode, drawerExpanded;
  final Pages currentSelected;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSidebar(
      onExpansionChange: onDrawerExpansionChange,
      alwaysExpanded: !tabletMode,
      expanded: drawerExpanded,
      iconSize: 30,
      textStyle: Theme.of(context).textTheme.titleMedium,
      fitItemsToBottom: true,
      borderRadius: 0,
      minWidth: 70,
      screenPadding: 0,
      // Kein Kopf mit Konto: Der Avatar steht in jeder Titelzeile, und das
      // Menü ist mit dreizehn Punkten ohnehin länger als der Bildschirm.
      titleTooltip: '',
      toggleTooltipCollapsed: tr(context).menuExpand,
      toggleTooltipExpanded: tr(context).menuCollapse,
      toggleTitle: const SizedBox(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      unselectedIconColor: Theme.of(context).iconTheme.color!,
      selectedIconColor: Theme.of(context).colorScheme.secondary,
      unselectedTextColor: Theme.of(context).textTheme.titleMedium!.color!,
      selectedTextColor: Theme.of(context).colorScheme.secondary,
      selectedIconBox: Theme.of(context).colorScheme.secondary.withAlpha(20),
      items: [
        CollapsibleItem(
          isSelected: currentSelected == Pages.homework,
          icon: Icons.assignment_rounded,
          text: tr(context).menuHomework,
          onPressed: goHome,
        ),
        CollapsibleItem(
            text: tr(context).menuAbsences,
            icon: Icons.hotel_rounded,
            isSelected: currentSelected == Pages.absences,
            onPressed: showAbsences),
        CollapsibleItem(
          text: tr(context).menuCalendar,
          icon: Icons.calendar_today_rounded,
          isSelected: currentSelected == Pages.calendar,
          onPressed: showCalendar,
        ),
        CollapsibleItem(
          onPressed: showGrades,
          isSelected: currentSelected == Pages.grades,
          text: tr(context).menuGrades,
          icon: Icons.grade_rounded,
        ),
        CollapsibleItem(
          text: tr(context).menuMessages,
          icon: Icons.message_rounded,
          isSelected: currentSelected == Pages.messages,
          onPressed: showMessages,
        ),
        CollapsibleItem(
          text: tr(context).menuCertificate,
          icon: Icons.workspace_premium_rounded,
          isSelected: currentSelected == Pages.certificate,
          onPressed: showCertificate,
        ),
        CollapsibleItem(
          text: tr(context).menuClassbook,
          icon: Icons.menu_book_rounded,
          isSelected: currentSelected == Pages.classbook,
          onPressed: showClassbook,
        ),
        CollapsibleItem(
          text: tr(context).menuHomeworkOverview,
          icon: Icons.task_alt_rounded,
          isSelected: currentSelected == Pages.homeworkOverview,
          onPressed: showHomeworkOverview,
        ),
        CollapsibleItem(
          text: tr(context).menuCourseContent,
          icon: Icons.folder_open_rounded,
          isSelected: currentSelected == Pages.courseContent,
          onPressed: showCourseContent,
        ),
        CollapsibleItem(
          hasDivider: true,
          text: tr(context).menuSettings,
          icon: Icons.settings_rounded,
          isSelected: currentSelected == Pages.settings,
          onPressed: showSettings,
        ),
        CollapsibleItem(
          hasDivider: true,
          text: tr(context).menuHelp,
          icon: Icons.help_rounded,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HelpFeedbackPage(),
            ),
          ),
        ),
        CollapsibleItem(
          hasDivider: true,
          text: tr(context).menuAbout,
          icon: Icons.info_rounded,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AboutHubPage(),
            ),
          ),
        ),
        CollapsibleItem(
          hasDivider: true,
          text: tr(context).menuLogout,
          icon: Icons.logout_rounded,
          onPressed: logout,
        ),
      ],
      body: const SizedBox(),
    );
  }
}
