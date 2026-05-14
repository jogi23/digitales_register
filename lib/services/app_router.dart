// Copyright (C) 2021 Michael Debertol
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
import 'package:dr/container/messages_container.dart';
import 'package:dr/main.dart';
import 'package:dr/pages.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/messages_provider.dart';
import 'package:dr/providers/profile_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRouter {
  final Ref _ref;

  const AppRouter(this._ref);

  void showProfile() {
    unawaited(navigatorKey!.currentState!.pushNamed("/profile"));
    unawaited(_ref.read(profileProvider.notifier).load());
  }

  void showChangeEmail() {
    unawaited(navigatorKey!.currentState!.pushNamed("/change_email"));
  }

  void showChangePass() {
    _navigateToLogin();
    _ref.read(loginProvider.notifier).setChangePassword(mustChange: false);
  }

  void showNotifications() {
    unawaited(navigatorKey!.currentState!.pushNamed("/notifications"));
  }

  void showMessage(int id) {
    navigatorKey!.currentState!.pop();
    _showMessages();
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
    _ref.read(settingsProvider.notifier).scrollToSubjectNicksSection();
    unawaited(navigatorKey!.currentState!.pushNamed("/settings"));
  }

  void _showMessages() {
    scaffoldKey!.currentState!
        .selectContentWidget(MessagesPageContainer(), Pages.messages);
    unawaited(_ref.read(messagesProvider.notifier).load());
  }

  void _navigateToLogin() {
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
}

final appRouterProvider = Provider<AppRouter>((ref) => AppRouter(ref));
