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

/// How the dashboard lays out its entries.
enum DashboardViewMode {
  /// One day after another, the long-standing default.
  list,

  /// A month grid; picking a day shows its entries.
  month,

  /// The timetable of one week, with lessons that have no entries dimmed.
  week;

  static DashboardViewMode fromName(String? name) =>
      DashboardViewMode.values.asNameMap()[name] ?? DashboardViewMode.list;
}

/// How the classbook lists what was taught.
///
/// The entries themselves come with every calendar week already; only the
/// arrangement differs.
enum ClassbookViewMode {
  /// Day after day, newest first, with a filter for one subject on top.
  ///
  /// The filter belongs to this arrangement rather than being an option of
  /// its own: without it the list answers "what did we do" but not "what did
  /// we do in German", and that is the question a classbook gets asked.
  chronological,

  /// One expandable row per subject, its entries underneath.
  bySubject;

  static ClassbookViewMode fromName(String? name) =>
      ClassbookViewMode.values.asNameMap()[name] ??
      ClassbookViewMode.chronological;
}

/// Lets copyWith tell "leave it alone" from "set it back to null".
const _unchanged = Object();

/// Star colour setting meaning "follow the app's accent colour".
/// The palette itself lives in ui/star_rating.dart.
const accentStarColorId = 'accent';

class SettingsState {
  SettingsState({
    this.noPasswordSaving = false,
    this.typeSorted = false,
    this.askWhenDelete = false,
    this.showCancelled = false,
    this.scrollToGrades = false,
    this.showCalendarNicksBar = true,
    this.showGradesDiagram = true,
    this.showAllSubjectsAverage = true,
    this.showSubjectAverage = true,
    this.dashboardMarkNewOrChangedEntries = true,
    this.dashboardDeduplicateEntries = true,
    this.dashboardColorBorders = false,
    this.calendarColorBackground = false,
    this.calendarShowTimes = true,
    this.dashboardViewMode = DashboardViewMode.list,
    this.classbookViewMode = ClassbookViewMode.chronological,
    this.dashboardColorTestsInRed = true,
    List<String>? ignoreForGradesAverage,
    List<String>? classbookSubjects,
    this.drawerFullyExpanded = true,
    this.starColor = accentStarColorId,
    this.language,
    this.messageSignature,
  })  : ignoreForGradesAverage = ignoreForGradesAverage ?? [],
        classbookSubjects = classbookSubjects ?? [];

  final bool noPasswordSaving;

  /// true = sort grades inside subjects by type;
  /// false = sort grades inside subjects by date
  final bool typeSorted;
  final bool askWhenDelete;
  final bool showCancelled;

  // Not serialized — ephemeral UI state for the settings page
  final bool scrollToGrades;

  final bool showCalendarNicksBar;
  final bool showGradesDiagram;
  final bool showAllSubjectsAverage;

  /// Whether each subject shows its own average next to its name.
  final bool showSubjectAverage;
  final bool dashboardMarkNewOrChangedEntries;
  final bool dashboardDeduplicateEntries;
  final bool dashboardColorBorders;
  final bool calendarColorBackground;

  /// Show a time axis next to the week grid.
  final bool calendarShowTimes;

  /// Whether the dashboard shows a list, a month grid or a week.
  final DashboardViewMode dashboardViewMode;

  /// Wie das Klassenbuch die Einträge anordnet.
  final ClassbookViewMode classbookViewMode;
  final bool dashboardColorTestsInRed;
  final List<String> ignoreForGradesAverage;

  /// Die Faecher, auf die das Klassenbuch eingeschraenkt ist.
  ///
  /// Leer heisst alle. Bewusst nicht kontouebergreifend: Welche Faecher es
  /// gibt, haengt am Konto, und die Auswahl eines Kindes sagt nichts ueber
  /// die eines anderen.
  final List<String> classbookSubjects;

  // Whether to fully expand the drawer if in tablet mode
  final bool drawerFullyExpanded;

  /// Id of the palette entry the competence stars are drawn in.
  /// See `starColors` in ui/star_rating.dart.
  final String starColor;

  /// Language code the app is shown in, null to follow the device.
  final String? language;

  /// The name last used to sign a message, so it does not have to be typed
  /// again. Bound to the account: who signs hangs on whose register it is.
  final String? messageSignature;

  SettingsState copyWith({
    bool? noPasswordSaving,
    bool? typeSorted,
    bool? askWhenDelete,
    bool? showCancelled,
    bool? scrollToGrades,
    bool? showCalendarNicksBar,
    bool? showGradesDiagram,
    bool? showAllSubjectsAverage,
    bool? showSubjectAverage,
    bool? dashboardMarkNewOrChangedEntries,
    bool? dashboardDeduplicateEntries,
    bool? dashboardColorBorders,
    bool? calendarColorBackground,
    bool? calendarShowTimes,
    DashboardViewMode? dashboardViewMode,
    ClassbookViewMode? classbookViewMode,
    bool? dashboardColorTestsInRed,
    List<String>? ignoreForGradesAverage,
    List<String>? classbookSubjects,
    bool? drawerFullyExpanded,
    String? starColor,
    Object? language = _unchanged,
    Object? messageSignature = _unchanged,
  }) =>
      SettingsState(
        noPasswordSaving: noPasswordSaving ?? this.noPasswordSaving,
        typeSorted: typeSorted ?? this.typeSorted,
        askWhenDelete: askWhenDelete ?? this.askWhenDelete,
        showCancelled: showCancelled ?? this.showCancelled,
        scrollToGrades: scrollToGrades ?? this.scrollToGrades,
        showCalendarNicksBar: showCalendarNicksBar ?? this.showCalendarNicksBar,
        showGradesDiagram: showGradesDiagram ?? this.showGradesDiagram,
        showAllSubjectsAverage:
            showAllSubjectsAverage ?? this.showAllSubjectsAverage,
        showSubjectAverage: showSubjectAverage ?? this.showSubjectAverage,
        dashboardMarkNewOrChangedEntries: dashboardMarkNewOrChangedEntries ??
            this.dashboardMarkNewOrChangedEntries,
        dashboardDeduplicateEntries:
            dashboardDeduplicateEntries ?? this.dashboardDeduplicateEntries,
        dashboardColorBorders:
            dashboardColorBorders ?? this.dashboardColorBorders,
        calendarColorBackground:
            calendarColorBackground ?? this.calendarColorBackground,
        calendarShowTimes: calendarShowTimes ?? this.calendarShowTimes,
        dashboardViewMode: dashboardViewMode ?? this.dashboardViewMode,
        classbookViewMode: classbookViewMode ?? this.classbookViewMode,
        dashboardColorTestsInRed:
            dashboardColorTestsInRed ?? this.dashboardColorTestsInRed,
        ignoreForGradesAverage:
            ignoreForGradesAverage ?? List.of(this.ignoreForGradesAverage),
        classbookSubjects:
            classbookSubjects ?? List.of(this.classbookSubjects),
        drawerFullyExpanded: drawerFullyExpanded ?? this.drawerFullyExpanded,
        starColor: starColor ?? this.starColor,
        language: identical(language, _unchanged)
            ? this.language
            : language as String?,
        messageSignature: identical(messageSignature, _unchanged)
            ? this.messageSignature
            : messageSignature as String?,
      );

  Map<String, dynamic> toJson() => {
        'noPasswordSaving': noPasswordSaving,
        'typeSorted': typeSorted,
        'askWhenDelete': askWhenDelete,
        'showCancelled': showCancelled,
        'showCalendarNicksBar': showCalendarNicksBar,
        'showGradesDiagram': showGradesDiagram,
        'showAllSubjectsAverage': showAllSubjectsAverage,
        'showSubjectAverage': showSubjectAverage,
        'dashboardMarkNewOrChangedEntries': dashboardMarkNewOrChangedEntries,
        'dashboardDeduplicateEntries': dashboardDeduplicateEntries,
        'dashboardColorBorders': dashboardColorBorders,
        'calendarColorBackground': calendarColorBackground,
        'calendarShowTimes': calendarShowTimes,
        'dashboardViewMode': dashboardViewMode.name,
        'classbookViewMode': classbookViewMode.name,
        'dashboardColorTestsInRed': dashboardColorTestsInRed,
        'ignoreForGradesAverage': ignoreForGradesAverage,
        'classbookSubjects': classbookSubjects,
        'drawerFullyExpanded': drawerFullyExpanded,
        'starColor': starColor,
        'language': language,
        'messageSignature': messageSignature,
      };

  factory SettingsState.fromJson(Map<dynamic, dynamic> json) => SettingsState(
        noPasswordSaving: json['noPasswordSaving'] as bool? ?? false,
        typeSorted: json['typeSorted'] as bool? ?? false,
        askWhenDelete: json['askWhenDelete'] as bool? ?? false,
        showCancelled: json['showCancelled'] as bool? ?? false,
        showCalendarNicksBar: json['showCalendarNicksBar'] as bool? ?? true,
        showGradesDiagram: json['showGradesDiagram'] as bool? ?? true,
        showAllSubjectsAverage: json['showAllSubjectsAverage'] as bool? ?? true,
        showSubjectAverage: json['showSubjectAverage'] as bool? ?? true,
        dashboardMarkNewOrChangedEntries:
            json['dashboardMarkNewOrChangedEntries'] as bool? ?? true,
        dashboardDeduplicateEntries:
            json['dashboardDeduplicateEntries'] as bool? ?? true,
        dashboardColorBorders: json['dashboardColorBorders'] as bool? ?? false,
        calendarColorBackground:
            json['calendarColorBackground'] as bool? ?? false,
        calendarShowTimes: json['calendarShowTimes'] as bool? ?? true,
        // Migrates the earlier boolean, which only knew list and month.
        dashboardViewMode: json['dashboardViewMode'] != null
            ? DashboardViewMode.fromName(json['dashboardViewMode'] as String?)
            : (json['dashboardCalendarView'] as bool? ?? false)
                ? DashboardViewMode.month
                : DashboardViewMode.list,
        classbookViewMode:
            ClassbookViewMode.fromName(json['classbookViewMode'] as String?),
        dashboardColorTestsInRed:
            json['dashboardColorTestsInRed'] as bool? ?? true,
        ignoreForGradesAverage:
            (json['ignoreForGradesAverage'] as List<dynamic>?)
                ?.cast<String>(),
        classbookSubjects:
            (json['classbookSubjects'] as List<dynamic>?)?.cast<String>(),
        drawerFullyExpanded: json['drawerFullyExpanded'] as bool? ?? true,
        starColor: json['starColor'] as String? ?? accentStarColorId,
        language: json['language'] as String?,
        messageSignature: json['messageSignature'] as String?,
      );

  /// The settings that belong to the app rather than to one account:
  /// everything under Aussehen, Fächer, Merkheft and Noten on the settings
  /// page. They are stored once for the whole app, so a parent with two
  /// children does not set them twice.
  ///
  /// What stays with the account: whether its password is saved, and the view
  /// toggles that sit on the screens themselves rather than in the settings.
  /// The theme and the subject colours were app-wide already, through
  /// SharedPreferences of their own.
  static const _globalKeys = {
    'dashboardColorBorders',
    'calendarColorBackground',
    'calendarShowTimes',
    'dashboardColorTestsInRed',
    'dashboardViewMode',
    'classbookViewMode',
    'dashboardMarkNewOrChangedEntries',
    'dashboardDeduplicateEntries',
    'askWhenDelete',
    'showGradesDiagram',
    'showAllSubjectsAverage',
    'showSubjectAverage',
    'starColor',
    'language',
    'ignoreForGradesAverage',
  };

  /// Only the app-wide settings, for storing them on their own.
  Map<String, dynamic> globalJson() => {
        for (final entry in toJson().entries)
          if (_globalKeys.contains(entry.key)) entry.key: entry.value,
      };

  /// This state with its app-wide settings taken from [json]. Keys the json
  /// does not carry keep their current value.
  SettingsState withGlobalJson(Map<dynamic, dynamic> json) =>
      SettingsState.fromJson({
        ...toJson(),
        for (final entry in json.entries)
          if (_globalKeys.contains(entry.key)) entry.key: entry.value,
      })
          // fromJson does not carry the ephemeral scroll flag.
          .copyWith(scrollToGrades: scrollToGrades);

  /// This state with its app-wide settings taken from [other].
  SettingsState withGlobalsFrom(SettingsState other) =>
      withGlobalJson(other.globalJson());

  static const _listEq = ListEquality<String>();

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SettingsState &&
        other.noPasswordSaving == noPasswordSaving &&
        other.typeSorted == typeSorted &&
        other.askWhenDelete == askWhenDelete &&
        other.showCancelled == showCancelled &&
        other.scrollToGrades == scrollToGrades &&
        other.showCalendarNicksBar == showCalendarNicksBar &&
        other.showGradesDiagram == showGradesDiagram &&
        other.showAllSubjectsAverage == showAllSubjectsAverage &&
        other.showSubjectAverage == showSubjectAverage &&
        other.dashboardMarkNewOrChangedEntries ==
            dashboardMarkNewOrChangedEntries &&
        other.dashboardDeduplicateEntries == dashboardDeduplicateEntries &&
        other.dashboardColorBorders == dashboardColorBorders &&
        other.calendarColorBackground == calendarColorBackground &&
        other.calendarShowTimes == calendarShowTimes &&
        other.dashboardViewMode == dashboardViewMode &&
        other.classbookViewMode == classbookViewMode &&
        other.dashboardColorTestsInRed == dashboardColorTestsInRed &&
        _listEq.equals(other.ignoreForGradesAverage, ignoreForGradesAverage) &&
        _listEq.equals(other.classbookSubjects, classbookSubjects) &&
        other.drawerFullyExpanded == drawerFullyExpanded &&
        other.starColor == starColor &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hashAll([
        noPasswordSaving,
        typeSorted,
        askWhenDelete,
        showCancelled,
        scrollToGrades,
        showCalendarNicksBar,
        showGradesDiagram,
        showAllSubjectsAverage,
        showSubjectAverage,
        dashboardMarkNewOrChangedEntries,
        dashboardDeduplicateEntries,
        dashboardColorBorders,
        calendarColorBackground,
        calendarShowTimes,
        dashboardViewMode,
        classbookViewMode,
        dashboardColorTestsInRed,
        ...ignoreForGradesAverage,
        ...classbookSubjects,
        drawerFullyExpanded,
        starColor,
        language,
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

  /// Weeks being fetched right now, by their Monday.
  ///
  /// Without this an empty week is indistinguishable from one still loading,
  /// and a week that genuinely has no lessons would spin forever.
  @BuiltValueField(serialize: false)
  BuiltSet<UtcDateTime> get loadingWeeks;

  @BuiltValueField(serialize: false)
  UtcDateTime? get currentMonday;
  @BuiltValueField(serialize: false)
  CalendarSelection? get selection;

  bool isLoadingWeek(UtcDateTime monday) => loadingWeeks.contains(monday);

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
    builder
      ..days = MapBuilder<UtcDateTime, CalendarDay>()
      ..loadingWeeks = SetBuilder<UtcDateTime>();
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

  /// When the request was recorded. Without it the log cannot be lined up
  /// with what the user just did, which is the only thing it is good for.
  DateTime get timestamp;

  /// Set when the request never got an answer at all. A failed request and
  /// one the server answered with nothing both leave [response] empty, and
  /// telling them apart is not possible afterwards.
  String? get error;

  factory NetworkProtocolItem(
          [Function(NetworkProtocolItemBuilder b)? updates]) =
      _$NetworkProtocolItem;
  NetworkProtocolItem._();
}
