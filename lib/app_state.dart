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

library;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:collection/collection.dart';
import 'package:dr/data.dart';
import 'package:dr/utc_date_time.dart';

part 'app_state.g.dart';

bool isDemoUser({required String? url, required String? username}) {
  return username == "demo-user-6540" &&
      url == "https://wertwerk-demo.digitalesregister.it";
}

abstract class AppState implements Built<AppState, AppStateBuilder> {
  @BuiltValueField(serialize: false)
  LoginState get loginState;
  NotificationState get notificationState;
  GradesState get gradesState;

  AbsencesState get absencesState;

  @BuiltValueField(serialize: false)
  Config? get config;
  @BuiltValueField(serialize: false)
  bool get noInternet;

  ProfileState get profileState;
  CalendarState get calendarState;
  MessagesState get messagesState;
  DashboardState get dashboardState;

  @BuiltValueField(serialize: false)
  NetworkProtocolState get networkProtocolState;

  @BuiltValueField(serialize: false)
  String? get url;
  static Serializer<AppState> get serializer => _$appStateSerializer;

  bool get isDemo => isDemoUser(url: url, username: loginState.username);

factory AppState([Function(AppStateBuilder b)? updates]) = _$AppState;
  AppState._();
  static void _initializeBuilder(AppStateBuilder builder) {
    builder
      ..loginState = LoginStateBuilder()
      ..notificationState = NotificationStateBuilder()
      ..gradesState = GradesStateBuilder()
      ..calendarState = CalendarStateBuilder()
      ..absencesState = AbsencesStateBuilder()
      ..messagesState = MessagesStateBuilder()
      ..dashboardState = DashboardStateBuilder()
      ..profileState = ProfileStateBuilder()
      ..networkProtocolState = NetworkProtocolStateBuilder()
      ..noInternet = false;
  }
}

abstract class MessagesState
    implements Built<MessagesState, MessagesStateBuilder> {
  BuiltList<Message> get messages;

  int? get showMessage;

  UtcDateTime? get lastFetched;

  static Serializer<MessagesState> get serializer => _$messagesStateSerializer;

  factory MessagesState([Function(MessagesStateBuilder b)? updates]) =
      _$MessagesState;
  MessagesState._();

  static void _initializeBuilder(MessagesStateBuilder builder) {
    builder.messages = ListBuilder();
  }
}

abstract class DashboardState
    implements Built<DashboardState, DashboardStateBuilder> {
  @BuiltValueField(serialize: false)
  bool get loading;
  bool get future;

  BuiltList<HomeworkType>? get blacklist;

  BuiltList<Day>? get allDays;

  static Serializer<DashboardState> get serializer => _$dashboardStateSerializer;

  factory DashboardState([Function(DashboardStateBuilder b)? updates]) =
      _$DashboardState;
  DashboardState._();
  static void _initializeBuilder(DashboardStateBuilder builder) {
    builder
      ..future = true
      ..loading = false
      ..blacklist = ListBuilder();
  }
}

abstract class LoginState implements Built<LoginState, LoginStateBuilder> {
  bool get loggedIn;
  bool get loading;

  String? get errorMsg;

  String? get username;
  bool get changePassword;
  bool get mustChangePassword;
  BuiltList<String> get otherAccounts;
  ResetPassState get resetPassState;
  factory LoginState([Function(LoginStateBuilder b)? updates]) = _$LoginState;
  LoginState._();
  static void _initializeBuilder(LoginStateBuilder builder) {
    builder
      ..loggedIn = false
      ..loading = false
      ..changePassword = false
      ..mustChangePassword = true
      ..resetPassState = ResetPassStateBuilder()
      ..otherAccounts = ListBuilder();
  }
}

abstract class ResetPassState
    implements Built<ResetPassState, ResetPassStateBuilder> {
  String? get message;
  bool get failure;

  String? get token;

  String? get email;

  String? get username;
  factory ResetPassState([Function(ResetPassStateBuilder b)? updates]) =
      _$ResetPassState;
  ResetPassState._();
  static void _initializeBuilder(ResetPassStateBuilder builder) {
    builder.failure = false;
  }
}

abstract class NotificationState
    implements Built<NotificationState, NotificationStateBuilder> {
  BuiltList<Notification>? get notifications;
  UtcDateTime? get lastFetched;

  bool get loading => notifications == null;
  bool get hasNotifications => !loading && notifications!.isNotEmpty;
  static Serializer<NotificationState> get serializer =>
      _$notificationStateSerializer;

  factory NotificationState([Function(NotificationStateBuilder b)? updates]) =
      _$NotificationState;
  // ignore: prefer_const_constructors_in_immutables
  NotificationState._();
}

abstract class Config implements Built<Config, ConfigBuilder> {
  int get userId;
  int get autoLogoutSeconds;
  String get fullName;
  String get imgSource;

  int? get currentSemesterMaybe;
  bool get isStudentOrParent;
  static Serializer<Config> get serializer => _$configSerializer;

  factory Config([Function(ConfigBuilder b)? updates]) = _$Config;
  // ignore: prefer_const_constructors_in_immutables
  Config._();
}

abstract class GradesState implements Built<GradesState, GradesStateBuilder> {
  @BuiltValueField(serialize: false)
  bool get loading;
  bool get hasGrades => subjects.isNotEmpty;
  Semester get semester;
  BuiltList<Subject> get subjects;

  /// If unknown: null

  @BuiltValueField(serialize: false)
  Semester? get serverSemester;

  @BuiltValueField(serialize: false)
  int? get pendingSubjectId;

  static Serializer<GradesState> get serializer => _$gradesStateSerializer;

  factory GradesState([Function(GradesStateBuilder b)? updates]) =
      _$GradesState;
  GradesState._();
  static void _initializeBuilder(GradesStateBuilder builder) {
    builder
      ..semester = Semester.all.toBuilder()
      ..subjects = ListBuilder()
      ..loading = false;
  }
}

class SubjectTheme {
  const SubjectTheme({this.thick = 0, this.color = 0});

  final int thick;
  final int color;

  SubjectTheme copyWith({int? thick, int? color}) =>
      SubjectTheme(thick: thick ?? this.thick, color: color ?? this.color);

  Map<String, dynamic> toJson() => {'thick': thick, 'color': color};

  factory SubjectTheme.fromJson(Map<dynamic, dynamic> json) => SubjectTheme(
        thick: json['thick'] as int? ?? 0,
        color: json['color'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is SubjectTheme && other.thick == thick && other.color == color;

  @override
  int get hashCode => Object.hash(thick, color);
}

abstract class Semester implements Built<Semester, SemesterBuilder> {
  String get name;

  int? get n;
  static final first = _$Semester((b) => b
    ..name = "1. Semester"
    ..n = 1);
  static final second = _$Semester((b) => b
    ..name = "2. Semester"
    ..n = 2);
  static final all = _$Semester((b) => b..name = "Beide Semester");
  static final values = [first, second, all];
  static Serializer<Semester> get serializer => _$semesterSerializer;
  factory Semester([void Function(SemesterBuilder)? updates]) = _$Semester;
  Semester._();
}

const _defaultSubjectNicks = <String, String>{
  "Deutsch": "Deu",
  "Mathematik": "Mat",
  "Latein": "Lat",
  "Religion": "Rel",
  "Englisch": "Eng",
  "Naturwissenschaften": "Nat",
  "Geschichte": "Gesch",
  "Italienisch": "Ita",
  "Bewegung und Sport": "Sport",
  "Recht und Wirtschaft": "Rw",
  "Griechisch": "Gr",
  "FÜ": "Fü",
};

class SettingsState {
  SettingsState({
    this.noPasswordSaving = false,
    this.noDataSaving = false,
    this.typeSorted = false,
    this.askWhenDelete = false,
    this.showCancelled = false,
    this.deleteDataOnLogout = false,
    Map<String, String>? subjectNicks,
    this.scrollToSubjectNicks = false,
    this.scrollToGrades = false,
    this.showCalendarNicksBar = true,
    this.showGradesDiagram = true,
    this.showAllSubjectsAverage = true,
    this.dashboardMarkNewOrChangedEntries = true,
    this.dashboardDeduplicateEntries = true,
    this.dashboardColorBorders = false,
    this.calendarColorBackground = false,
    this.dashboardColorTestsInRed = true,
    Map<String, SubjectTheme>? subjectThemes,
    List<String>? ignoreForGradesAverage,
    this.drawerFullyExpanded = true,
  })  : subjectNicks = subjectNicks ?? Map.of(_defaultSubjectNicks),
        subjectThemes = subjectThemes ?? {},
        ignoreForGradesAverage = ignoreForGradesAverage ?? [];

  final bool noPasswordSaving;
  final bool noDataSaving;

  /// true = sort grades inside subjects by type;
  /// false = sort grades inside subjects by date
  final bool typeSorted;
  final bool askWhenDelete;
  final bool showCancelled;
  final bool deleteDataOnLogout;
  final Map<String, String> subjectNicks;

  // Not serialized — ephemeral UI state for the settings page
  final bool scrollToSubjectNicks;
  final bool scrollToGrades;

  final bool showCalendarNicksBar;
  final bool showGradesDiagram;
  final bool showAllSubjectsAverage;
  final bool dashboardMarkNewOrChangedEntries;
  final bool dashboardDeduplicateEntries;
  final bool dashboardColorBorders;
  final bool calendarColorBackground;
  final bool dashboardColorTestsInRed;
  final Map<String, SubjectTheme> subjectThemes;
  final List<String> ignoreForGradesAverage;

  // Whether to fully expand the drawer if in tablet mode
  final bool drawerFullyExpanded;

  SettingsState copyWith({
    bool? noPasswordSaving,
    bool? noDataSaving,
    bool? typeSorted,
    bool? askWhenDelete,
    bool? showCancelled,
    bool? deleteDataOnLogout,
    Map<String, String>? subjectNicks,
    bool? scrollToSubjectNicks,
    bool? scrollToGrades,
    bool? showCalendarNicksBar,
    bool? showGradesDiagram,
    bool? showAllSubjectsAverage,
    bool? dashboardMarkNewOrChangedEntries,
    bool? dashboardDeduplicateEntries,
    bool? dashboardColorBorders,
    bool? calendarColorBackground,
    bool? dashboardColorTestsInRed,
    Map<String, SubjectTheme>? subjectThemes,
    List<String>? ignoreForGradesAverage,
    bool? drawerFullyExpanded,
  }) =>
      SettingsState(
        noPasswordSaving: noPasswordSaving ?? this.noPasswordSaving,
        noDataSaving: noDataSaving ?? this.noDataSaving,
        typeSorted: typeSorted ?? this.typeSorted,
        askWhenDelete: askWhenDelete ?? this.askWhenDelete,
        showCancelled: showCancelled ?? this.showCancelled,
        deleteDataOnLogout: deleteDataOnLogout ?? this.deleteDataOnLogout,
        subjectNicks: subjectNicks ?? Map.of(this.subjectNicks),
        scrollToSubjectNicks: scrollToSubjectNicks ?? this.scrollToSubjectNicks,
        scrollToGrades: scrollToGrades ?? this.scrollToGrades,
        showCalendarNicksBar: showCalendarNicksBar ?? this.showCalendarNicksBar,
        showGradesDiagram: showGradesDiagram ?? this.showGradesDiagram,
        showAllSubjectsAverage:
            showAllSubjectsAverage ?? this.showAllSubjectsAverage,
        dashboardMarkNewOrChangedEntries: dashboardMarkNewOrChangedEntries ??
            this.dashboardMarkNewOrChangedEntries,
        dashboardDeduplicateEntries:
            dashboardDeduplicateEntries ?? this.dashboardDeduplicateEntries,
        dashboardColorBorders:
            dashboardColorBorders ?? this.dashboardColorBorders,
        calendarColorBackground:
            calendarColorBackground ?? this.calendarColorBackground,
        dashboardColorTestsInRed:
            dashboardColorTestsInRed ?? this.dashboardColorTestsInRed,
        subjectThemes: subjectThemes ?? Map.of(this.subjectThemes),
        ignoreForGradesAverage:
            ignoreForGradesAverage ?? List.of(this.ignoreForGradesAverage),
        drawerFullyExpanded: drawerFullyExpanded ?? this.drawerFullyExpanded,
      );

  Map<String, dynamic> toJson() => {
        'noPasswordSaving': noPasswordSaving,
        'noDataSaving': noDataSaving,
        'typeSorted': typeSorted,
        'askWhenDelete': askWhenDelete,
        'showCancelled': showCancelled,
        'deleteDataOnLogout': deleteDataOnLogout,
        'subjectNicks': subjectNicks,
        'showCalendarNicksBar': showCalendarNicksBar,
        'showGradesDiagram': showGradesDiagram,
        'showAllSubjectsAverage': showAllSubjectsAverage,
        'dashboardMarkNewOrChangedEntries': dashboardMarkNewOrChangedEntries,
        'dashboardDeduplicateEntries': dashboardDeduplicateEntries,
        'dashboardColorBorders': dashboardColorBorders,
        'calendarColorBackground': calendarColorBackground,
        'dashboardColorTestsInRed': dashboardColorTestsInRed,
        'subjectThemes': {
          for (final e in subjectThemes.entries) e.key: e.value.toJson(),
        },
        'ignoreForGradesAverage': ignoreForGradesAverage,
        'drawerFullyExpanded': drawerFullyExpanded,
      };

  factory SettingsState.fromJson(Map<dynamic, dynamic> json) => SettingsState(
        noPasswordSaving: json['noPasswordSaving'] as bool? ?? false,
        noDataSaving: json['noDataSaving'] as bool? ?? false,
        typeSorted: json['typeSorted'] as bool? ?? false,
        askWhenDelete: json['askWhenDelete'] as bool? ?? false,
        showCancelled: json['showCancelled'] as bool? ?? false,
        deleteDataOnLogout: json['deleteDataOnLogout'] as bool? ?? false,
        subjectNicks:
            (json['subjectNicks'] as Map<dynamic, dynamic>?)?.cast<String, String>(),
        showCalendarNicksBar: json['showCalendarNicksBar'] as bool? ?? true,
        showGradesDiagram: json['showGradesDiagram'] as bool? ?? true,
        showAllSubjectsAverage: json['showAllSubjectsAverage'] as bool? ?? true,
        dashboardMarkNewOrChangedEntries:
            json['dashboardMarkNewOrChangedEntries'] as bool? ?? true,
        dashboardDeduplicateEntries:
            json['dashboardDeduplicateEntries'] as bool? ?? true,
        dashboardColorBorders: json['dashboardColorBorders'] as bool? ?? false,
        calendarColorBackground:
            json['calendarColorBackground'] as bool? ?? false,
        dashboardColorTestsInRed:
            json['dashboardColorTestsInRed'] as bool? ?? true,
        subjectThemes: {
          for (final e
              in (json['subjectThemes'] as Map<dynamic, dynamic>? ?? {}).entries)
            e.key as String:
                SubjectTheme.fromJson(e.value as Map<dynamic, dynamic>),
        },
        ignoreForGradesAverage:
            (json['ignoreForGradesAverage'] as List<dynamic>?)
                ?.cast<String>(),
        drawerFullyExpanded: json['drawerFullyExpanded'] as bool? ?? true,
      );

  static const _mapEq = MapEquality<String, String>();
  static const _themeMapEq = MapEquality<String, SubjectTheme>();
  static const _listEq = ListEquality<String>();

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SettingsState &&
        other.noPasswordSaving == noPasswordSaving &&
        other.noDataSaving == noDataSaving &&
        other.typeSorted == typeSorted &&
        other.askWhenDelete == askWhenDelete &&
        other.showCancelled == showCancelled &&
        other.deleteDataOnLogout == deleteDataOnLogout &&
        _mapEq.equals(other.subjectNicks, subjectNicks) &&
        other.scrollToSubjectNicks == scrollToSubjectNicks &&
        other.scrollToGrades == scrollToGrades &&
        other.showCalendarNicksBar == showCalendarNicksBar &&
        other.showGradesDiagram == showGradesDiagram &&
        other.showAllSubjectsAverage == showAllSubjectsAverage &&
        other.dashboardMarkNewOrChangedEntries ==
            dashboardMarkNewOrChangedEntries &&
        other.dashboardDeduplicateEntries == dashboardDeduplicateEntries &&
        other.dashboardColorBorders == dashboardColorBorders &&
        other.calendarColorBackground == calendarColorBackground &&
        other.dashboardColorTestsInRed == dashboardColorTestsInRed &&
        _themeMapEq.equals(other.subjectThemes, subjectThemes) &&
        _listEq.equals(other.ignoreForGradesAverage, ignoreForGradesAverage) &&
        other.drawerFullyExpanded == drawerFullyExpanded;
  }

  @override
  int get hashCode => Object.hashAll([
        noPasswordSaving,
        noDataSaving,
        typeSorted,
        askWhenDelete,
        showCancelled,
        deleteDataOnLogout,
        ...subjectNicks.entries.map((e) => Object.hash(e.key, e.value)),
        scrollToSubjectNicks,
        scrollToGrades,
        showCalendarNicksBar,
        showGradesDiagram,
        showAllSubjectsAverage,
        dashboardMarkNewOrChangedEntries,
        dashboardDeduplicateEntries,
        dashboardColorBorders,
        calendarColorBackground,
        dashboardColorTestsInRed,
        ...subjectThemes.entries.map((e) => Object.hash(e.key, e.value)),
        ...ignoreForGradesAverage,
        drawerFullyExpanded,
      ]);
}

abstract class ProfileState
    implements Built<ProfileState, ProfileStateBuilder> {
  factory ProfileState([Function(ProfileStateBuilder b)? updates]) =
      _$ProfileState;
  ProfileState._();
  static Serializer<ProfileState> get serializer => _$profileStateSerializer;

  String? get email;
  String? get username;
  String? get roleName;
  String? get name;
  bool? get sendNotificationEmails;
}

abstract class AbsencesState
    implements Built<AbsencesState, AbsencesStateBuilder> {
  factory AbsencesState([Function(AbsencesStateBuilder b)? updates]) =
      _$AbsencesState;
  AbsencesState._();
  static Serializer<AbsencesState> get serializer => _$absencesStateSerializer;

  AbsenceStatistic? get statistic;
  BuiltList<AbsenceGroup> get absences;
  BuiltList<FutureAbsence> get futureAbsences;

  UtcDateTime? get lastFetched;

  static void _initializeBuilder(AbsencesStateBuilder builder) {
    builder
      ..absences = ListBuilder<AbsenceGroup>()
      ..futureAbsences = ListBuilder<FutureAbsence>();
  }
}

abstract class CalendarState
    implements Built<CalendarState, CalendarStateBuilder> {
  BuiltMap<UtcDateTime, CalendarDay> get days;

  @BuiltValueField(serialize: false)
  UtcDateTime? get currentMonday;
  @BuiltValueField(serialize: false)
  CalendarSelection? get selection;

  Iterable<CalendarDay> get currentDays {
    return daysForWeek(currentMonday!);
  }

  Iterable<CalendarDay> daysForWeek(UtcDateTime monday) {
    return days.values.where((d) {
      final date = UtcDateTime(d.date.year, d.date.month, d.date.day);
      return !date.isBefore(monday) &&
          date.isBefore(monday.add(const Duration(days: 7)));
    });
  }

  factory CalendarState([Function(CalendarStateBuilder b)? updates]) =
      _$CalendarState;
  CalendarState._();
  static Serializer<CalendarState> get serializer => _$calendarStateSerializer;
  static void _initializeBuilder(CalendarStateBuilder builder) {
    builder.days = MapBuilder<UtcDateTime, CalendarDay>();
  }
}

abstract class CalendarSelection
    implements Built<CalendarSelection, CalendarSelectionBuilder> {
  UtcDateTime get date;
  int? get hour;

  factory CalendarSelection([Function(CalendarSelectionBuilder b)? updates]) =
      _$CalendarSelection;
  CalendarSelection._();
  static Serializer<CalendarSelection> get serializer =>
      _$calendarSelectionSerializer;
}

abstract class NetworkProtocolState
    implements Built<NetworkProtocolState, NetworkProtocolStateBuilder> {
  BuiltList<NetworkProtocolItem> get items;

  factory NetworkProtocolState(
          [Function(NetworkProtocolStateBuilder b)? updates]) =
      _$NetworkProtocolState;
  NetworkProtocolState._();

  static void _initializeBuilder(NetworkProtocolStateBuilder builder) {
    builder.items = ListBuilder();
  }
}

abstract class NetworkProtocolItem
    implements Built<NetworkProtocolItem, NetworkProtocolItemBuilder> {
  String get address;
  String get parameters;
  String get response;

  factory NetworkProtocolItem(
          [Function(NetworkProtocolItemBuilder b)? updates]) =
      _$NetworkProtocolItem;
  NetworkProtocolItem._();
}
