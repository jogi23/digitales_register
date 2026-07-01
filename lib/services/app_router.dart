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

import 'dart:async';

import 'package:dr/app_state.dart';
import 'package:dr/container/absences_page_container.dart';
import 'package:dr/container/calendar_container.dart';
import 'package:dr/container/grades_page_container.dart';
import 'package:dr/container/messages_container.dart';
import 'package:dr/container/settings_page.dart';
import 'package:dr/main.dart';
import 'package:dr/pages.dart';
import 'package:dr/providers/absences_provider.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/certificate_provider.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/messages_provider.dart';
import 'package:dr/providers/profile_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/certificate.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRouter {
  final Ref _ref;

  const AppRouter(this._ref);

  void showLogin() {
    Route? currentRoute;
    navigatorKey!.currentState?.popUntil((route) {
      currentRoute = route;
      return true;
    });
    if (currentRoute?.settings.name != "/login") {
      unawaited(navigatorKey!.currentState?.pushNamed("/login"));
    }
    _ref.read(loginProvider.notifier).showLogin();
  }

  void showProfile() {
    unawaited(navigatorKey!.currentState!.pushNamed("/profile"));
    unawaited(_ref.read(profileProvider.notifier).load());
  }

  void showChangeEmail() {
    unawaited(navigatorKey!.currentState!.pushNamed("/change_email"));
  }

  void showChangePass() {
    showLogin();
    _ref.read(loginProvider.notifier).setChangePassword(mustChange: false);
  }

  void showNotifications() {
    unawaited(navigatorKey!.currentState!.pushNamed("/notifications"));
  }

  void showSettings() {
    _ref.read(settingsProvider.notifier).resetScroll();
    scaffoldKey!.currentState!
        .selectContentWidget(SettingsPageContainer(), Pages.settings);
  }

  void showCalendar() {
    scaffoldKey!.currentState!
        .selectContentWidget(CalendarContainer(), Pages.calendar);
    _ref.read(calendarProvider.notifier).clearSelection();
    _ref.read(calendarProvider.notifier).setCurrentMonday(toMonday(now));
    unawaited(_ref.read(calendarProvider.notifier).load(toMonday(now)));
  }

  void showGrades() {
    scaffoldKey!.currentState!
        .selectContentWidget(const GradesPageContainer(), Pages.grades);
    unawaited(_ref
        .read(gradesProvider.notifier)
        .load(_ref.read(gradesProvider).semester));
  }

  void showGradeDetail(int objectId) {
    navigatorKey!.currentState!.pop();
    showGrades();
    unawaited(
        _ref.read(gradesProvider.notifier).requestSubjectDetail(objectId));
  }

  void showAbsences() {
    scaffoldKey!.currentState!
        .selectContentWidget(const AbsencesPageContainer(), Pages.absences);
    unawaited(_ref.read(absencesProvider.notifier).load());
  }

  void showCertificate() {
    scaffoldKey!.currentState!
        .selectContentWidget(const Certificate(), Pages.certificate);
    unawaited(_ref.read(certificateProvider.notifier).load());
  }

  void showMessages() {
    scaffoldKey!.currentState!
        .selectContentWidget(MessagesPageContainer(), Pages.messages);
    unawaited(_ref.read(messagesProvider.notifier).load());
  }

  void showMessage(int id) {
    navigatorKey!.currentState!.pop();
    showMessages();
    _ref.read(messagesProvider.notifier).select(id);
  }

  void showEditGradesAverageSettings() {
    _ref.read(settingsProvider.notifier).scrollToGradesSection();
    unawaited(navigatorKey!.currentState!.pushNamed("/settings"));
  }

  void showGradeCalculator() {
    unawaited(navigatorKey!.currentState!.pushNamed("/gradeCalculator"));
    unawaited(_ref.read(gradesProvider.notifier).load(Semester.all));
  }

  void showGradesChart() {
    unawaited(navigatorKey!.currentState!.pushNamed("/gradesChart"));
  }

  void showEditCalendarSubjectNicks() {
    unawaited(
      navigatorKey!.currentState!
          .pushNamed("/subjectAppearance", arguments: true),
    );
  }
}

final appRouterProvider = Provider<AppRouter>((ref) => AppRouter(ref));
