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

part of 'middleware.dart';

enum Pages {
  homework,
  grades,
  absences,
  calendar,
  certificate,
  messages,
  settings,
}

// This allows tests to just include the routingMiddleware
@visibleForTesting
final routingMiddleware =
    MiddlewareBuilder<AppState, AppStateBuilder, AppActions>()
      ..add(RoutingActionsNames.showLogin, _showLogin)
      ..add(RoutingActionsNames.showRequestPassReset, _showRequestPassReset)
      ..add(RoutingActionsNames.showPassReset, _showPassReset)
      ..add(RoutingActionsNames.showChangeEmail, _showChangeEmail)
      ..add(RoutingActionsNames.showProfile, _showProfile)
      ..add(RoutingActionsNames.showNotifications, _showNotifications)
      ..add(RoutingActionsNames.showSettings, _showSettings)
      ..add(RoutingActionsNames.showEditCalendarSubjectNicks,
          _showEditCalendarSubjectNicks)
      ..add(RoutingActionsNames.showEditGradesAverageSettings,
          _showEditGradesAverageSettings)
      ..add(RoutingActionsNames.showCalendar, _showCalendar)
      ..add(RoutingActionsNames.showAbsences, _showAbsences)
      ..add(RoutingActionsNames.showGradesChart, _showGradesChart)
      ..add(RoutingActionsNames.showGrades, _showGrades)
      ..add(RoutingActionsNames.showGradeCalculator, _showGradeCalculator)
      ..add(RoutingActionsNames.showCertificate, _showCertificate)
      ..add(RoutingActionsNames.showMessages, _showMessages)
      ..add(RoutingActionsNames.showMessage, _showMessage);

Future<void> _showLogin(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  await next(action);
  // hack since the current route is not exposed otherwise
  Route? currentRoute;
  navigatorKey!.currentState?.popUntil((route) {
    currentRoute = route;
    // by returning true here no route is actually popped.
    return true;
  });

  if (currentRoute?.settings.name != "/login") {
    unawaited(navigatorKey!.currentState?.pushNamed("/login"));
  }
}

Future<void> _showRequestPassReset(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<String> action) async {
  await api.actions.setUrl(action.payload);
  unawaited(navigatorKey!.currentState!.pushNamed("/request_pass_reset"));
  await next(action);
}

Future<void> _showPassReset(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  unawaited(navigatorKey!.currentState!.pushNamed("/pass_reset"));
  await next(action);
}

Future<void> _showChangeEmail(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  unawaited(navigatorKey!.currentState!.pushNamed("/change_email"));
  await next(action);
}

Future<void> _showProfile(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  unawaited(navigatorKey!.currentState!.pushNamed("/profile"));
  unawaited(providerContainer.read(profileProvider.notifier).load());
  await next(action);
}

Future<void> _showNotifications(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  unawaited(navigatorKey!.currentState!.pushNamed("/notifications"));
  await next(action);
}

Future<void> _showSettings(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  providerContainer.read(settingsProvider.notifier).resetScroll();
  scaffoldKey!.currentState!
      .selectContentWidget(SettingsPageContainer(), Pages.settings);
  await next(action);
}

Future<void> _showEditCalendarSubjectNicks(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  providerContainer
      .read(settingsProvider.notifier)
      .scrollToSubjectNicksSection();
  await next(action);
  unawaited(navigatorKey!.currentState!.pushNamed("/settings"));
}

Future<void> _showEditGradesAverageSettings(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  providerContainer.read(settingsProvider.notifier).scrollToGradesSection();
  unawaited(navigatorKey!.currentState!.pushNamed("/settings"));
  await next(action);
}

Future<void> _showCalendar(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  scaffoldKey!.currentState!
      .selectContentWidget(CalendarContainer(), Pages.calendar);
  providerContainer.read(calendarProvider.notifier).clearSelection();
  providerContainer
      .read(calendarProvider.notifier)
      .setCurrentMonday(toMonday(now));
  unawaited(
    providerContainer.read(calendarProvider.notifier).load(toMonday(now)),
  );

  await next(action);
}

Future<void> _showGrades(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  scaffoldKey!.currentState!
      .selectContentWidget(const GradesPageContainer(), Pages.grades);
  unawaited(providerContainer
      .read(gradesProvider.notifier)
      .load(providerContainer.read(gradesProvider).semester));
  await next(action);
}

Future<void> _showAbsences(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  scaffoldKey!.currentState!
      .selectContentWidget(const AbsencesPageContainer(), Pages.absences);
  unawaited(providerContainer.read(absencesProvider.notifier).load());
  await next(action);
}

Future<void> _showCertificate(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  scaffoldKey!.currentState!
      .selectContentWidget(const Certificate(), Pages.certificate);
  unawaited(providerContainer.read(certificateProvider.notifier).load());
  await next(action);
}

Future<void> _showMessages(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  scaffoldKey!.currentState!
      .selectContentWidget(MessagesPageContainer(), Pages.messages);
  unawaited(providerContainer.read(messagesProvider.notifier).load());
  await next(action);
}

Future<void> _showMessage(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<int> action) async {
  navigatorKey!.currentState!.pop();
  await api.actions.routingActions.showMessages();
  providerContainer.read(messagesProvider.notifier).select(action.payload);
  await next(action);
}

Future<void> _showGradesChart(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  unawaited(navigatorKey!.currentState!.pushNamed("/gradesChart"));
  await next(action);
}

Future<void> _showGradeCalculator(
    MiddlewareApi<AppState, AppStateBuilder, AppActions> api,
    ActionHandler next,
    Action<void> action) async {
  unawaited(navigatorKey!.currentState!.pushNamed("/gradeCalculator"));
  unawaited(providerContainer.read(gradesProvider.notifier).load(Semester.all));
  await next(action);
}
