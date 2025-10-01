/*
 * Copyright (c) 2025 Code42Maestro
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:async';

import 'absence_objects.dart';
import 'auth.dart';
import 'objects.dart';
import 'requests.dart';
import 'timetable_objects.dart';
import 'util.dart';

/// The main object to interact with the Untis Mobile API
class UntisSession {
  UntisSession._(String server, String school, this.username, this._password)
      : apiEndpoint = apiTemplate
            .replaceAll('%SRV%', server)
            .replaceAll('%SCHOOL%', school);

  /// The api endpoint, i. e. [apiTemplate], replaced with values
  final String apiEndpoint;

  /// The username of the user logged in
  final String username;

  late String _appSharedSecret;
  final String _password;

  UntisAuthentication get _auth =>
      UntisAuthentication.currentTime(username, _appSharedSecret);

  /// Base = https://$server/WebUntis/jsonrpc_intern.do?school=school
  ///
  /// I use only the base as this is the minimum requirement
  ///
  /// Version a5.12.5 :
  ///
  /// Base + |>  &m=%METHOD%&a=false&s=$server <|  &v=a5.12.5
  ///
  /// This version includes the method and the server (again) in the url.
  /// The use of a=false is unknown
  ///
  /// Version a5.2.3:
  ///
  /// Base + &v=a5.2.3
  ///
  /// In this version the url remains static between every method request
  static const String apiTemplate =
      'https://%SRV%/WebUntis/jsonrpc_intern.do?school=%SCHOOL%';

  /// The only way to construct a instance of UntisSession.
  ///
  /// The function uses [server], [school], [username] and [password] to
  /// set the API endpoint and login.
  static Future<UntisSession> init(
      String server, String school, String username, String password) async {
    final UntisSession s = UntisSession._(server, school, username, password);
    await s.login();
    return s;
  }

  /// Gets the "appSharedSecret", as untis calls it, and saves it.
  /// This is necessary for calculating the one-time-pad code, that is used
  /// for auth
  Future<void> login() async {
    _appSharedSecret =
        (await AppSharedSecretRequest(apiEndpoint, username, _password)
            .request())!;
  }

  /// Get StudentData, for more specific information of what this is,
  /// refer to [UntisStudentData] iself.
  Future<UntisStudentData> getUserData() async {
    final Map<String, dynamic> json =
        (await UserDataRequest(apiEndpoint, _auth).request())!;
    unawaited(_refreshMasterData(json['masterData']));
    return UntisStudentData.fromJson(json['userData']);
  }

  /// Gets Absences within defined time period and with search parameters.
  ///
  /// You can provide a [startDate], which defaults to [DateTime.now()].
  /// An [endDate], which defaults to [startDate + 1 year]. Additionally whether
  /// it should include absences, that are excused or/and ones that are not excused.
  Future<List<UntisAbsence>> getAbsences(
      {DateTime? startDate,
      DateTime? endDate,
      bool includeExcuseds = true,
      bool includeUnExcuseds = false}) async {
    startDate ??= DateTime.now();
    endDate ??= startDate.add(const Duration(days: 356));

    final AbsencesRequest request = AbsencesRequest(apiEndpoint, _auth,
        startDate, endDate, includeExcuseds, includeUnExcuseds);
    final Map<String, dynamic> json = (await request.request())!;
    return <UntisAbsence>[
      for (final Map<String, dynamic> entry in json['absences'])
        await UntisAbsence.fromJson(this, entry)
    ];
  }

  /// Gets Exams within defined time period and with search parameters.
  ///
  /// You can provide a [startDate], which defaults to [DateTime.now()].
  /// An [endDate], which defaults to [startDate + 7 days]. Additionally
  /// an [studentId] can be specified.
  Future<List<UntisExam>> getExams(
      {DateTime? startDate,
      DateTime? endDate,
      UntisElementDescriptor? studentId}) async {
    startDate ??= DateTime.now();
    endDate ??= startDate.add(const Duration(days: 7));

    final ExamsRequest request = ExamsRequest(apiEndpoint, _auth,
        studentId ?? (await studentData).id, startDate, endDate);
    final Map<String, dynamic> json = (await request.request())!;
    return <UntisExam>[
      for (final Map<String, dynamic> entry in json['exams'])
        UntisExam.fromJson(entry)
    ];
  }

  /// Gets Homeworks within defined time period and with search parameters.
  ///
  /// You can provide a [startDate], which defaults to [DateTime.now()].
  /// An [endDate], which defaults to [startDate + 7 days]. Additionally
  /// an [id] can be specified.
  // TODO(Code42Maestro): Establish the fetching of the lesson period
  Future<List<UntisHomework>> getHomework(
      {DateTime? startDate,
      DateTime? endDate,
      UntisElementDescriptor? id}) async {
    startDate ??= DateTime.now();
    endDate ??= startDate.add(const Duration(days: 7));

    final HomeworkRequest request = HomeworkRequest(
        apiEndpoint, _auth, id ?? (await studentData).id, startDate, endDate);
    final Map<String, dynamic> json = (await request.request())!;
    return <UntisHomework>[
      for (final Map<String, dynamic> entry in json['homeWorks'])
        UntisHomework.fromJson(entry)
    ];
  }

  /// Returns subjects, which are in the current timetable of the user/class
  ///
  /// The [id] argument is the students id, but this can be specified to
  /// fetch a student's or a class's timetable.
  /// Additionally the argument [timeSpan] should be a reasonable time span.
  /// The time span is measured from [DateTime.now()] on.
  /// The default is 128 days.
  Future<List<UntisSubject>> getCurrentSubjects(
      {UntisElementDescriptor? id, Duration? timeSpan}) async {
    id ??= (await studentData).id;
    timeSpan ??= const Duration(days: 128);

    final List<UntisPeriod> periods =
        await getTimetablePeriods(id, endDate: DateTime.now().add(timeSpan));
    final Iterable<UntisSubject> subjectsInTimeSpan =
        periods.expand((UntisPeriod e) => e.subjects);
    return (await subjects).where(subjectsInTimeSpan.contains).toList();
  }

  /// Gets Timetable with defined time period.
  ///
  /// You can provide a [startDate], which defaults to [DateTime.now()].
  /// An [endDate], which defaults to [startDate + 7 days] and an [id],
  /// which defaults to student id and describes the timetable to get.
  /// These can be from a class or the student.
  Future<UntisTimetable> getTimetable(
      {UntisElementDescriptor? id,
      DateTime? startDate,
      DateTime? endDate}) async {
    startDate ??= DateTime.now();
    endDate ??= startDate.add(const Duration(days: 7));

    final TimetableRequest request = TimetableRequest(apiEndpoint, _auth,
        id ?? (await studentData).id, masterDataTimestamp, startDate, endDate);
    final Map<String, dynamic> json = (await request.request())!;
    unawaited(_refreshMasterData(json['masterData']));
    return UntisTimetable.fromJson(this, json['timetable']);
  }

  /// Gets the periods of Timetable with defined time period.
  /// This is nothing more than [getTimetable(...).allPeriods]
  ///
  /// Refer to [getTimetable] for more information
  Future<List<UntisPeriod>> getTimetablePeriods(UntisElementDescriptor? id,
      {DateTime? startDate, DateTime? endDate}) async {
    return (await getTimetable(id: id, startDate: startDate, endDate: endDate))
        .periods;
  }

  List<UntisAbsenceReason> _absenceReasons = <UntisAbsenceReason>[];

  /// These are reasons for not being in a lesson.
  ///
  /// This can be coming late or being ill, but there are other reasons too.
  Future<List<UntisAbsenceReason>> get absenceReasons =>
      execAsyncFuncIfNull(_absenceReasons, _fetchAndCacheMasterData);

  List<UntisDuty>? _duties = <UntisDuty>[];

  /// These are possible duties that students need to fulfill -
  /// for example wiping the board
  Future<List<UntisDuty>> get duties =>
      execAsyncFuncIfNull(_duties, _fetchAndCacheMasterData);

  List<UntisEventReason>? _eventReasons = <UntisEventReason>[];

  /// Don't know how this is used, but these could be reasons for students or
  /// for classes.
  ///
  /// A few examples are for students, active participation,
  /// passive participation, no homework,
  /// no sport clothes or no working material
  ///
  /// For whole classes there are these, instruction(indoctrination) or the
  /// messaging of the current grades.
  Future<List<UntisEventReason>> get eventReasons =>
      execAsyncFuncIfNull(_eventReasons, _fetchAndCacheMasterData);

  List<UntisEventReasonGroup>? _eventReasonGroups = <UntisEventReasonGroup>[];

  /// The different "types" of event reasons (whatever event reasons are), used
  /// by [UntisEventReason]
  ///
  /// These are usually, notice, participation in sports and
  /// material and homework
  Future<List<UntisEventReasonGroup>> get eventReasonGroups =>
      execAsyncFuncIfNull(_eventReasonGroups, _fetchAndCacheMasterData);

  List<UntisExcuseStatus>? _excuseStates = <UntisExcuseStatus>[];

  /// Possible excuse states why you did not come to a lesson.
  ///
  /// This is most likely to be excused and
  Future<List<UntisExcuseStatus>> get excuseStates =>
      execAsyncFuncIfNull(_excuseStates, _fetchAndCacheMasterData);

  List<UntisHoliday>? _holidays = <UntisHoliday>[];

  /// The time periods, where you don't have school
  Future<List<UntisHoliday>> get holidays =>
      execAsyncFuncIfNull(_holidays, _fetchAndCacheMasterData);

  List<UntisClass>? _classes = <UntisClass>[];

  /// All [UntisClass]es of this school
  Future<List<UntisClass>> get classes =>
      execAsyncFuncIfNull(_classes, _fetchAndCacheMasterData);

  List<UntisRoom>? _rooms = <UntisRoom>[];

  /// All [UntisRoom]s of this school
  Future<List<UntisRoom>> get rooms =>
      execAsyncFuncIfNull(_rooms, _fetchAndCacheMasterData);

  List<UntisSubject>? _subjects = <UntisSubject>[];

  /// All [UntisSubject]s of this school
  Future<List<UntisSubject>> get subjects =>
      execAsyncFuncIfNull(_subjects, _fetchAndCacheMasterData);

  List<UntisTeacher>? _teachers = <UntisTeacher>[];

  /// All [UntisTeacher]s of this school
  Future<List<UntisTeacher>> get teachers =>
      execAsyncFuncIfNull(_teachers, _fetchAndCacheMasterData);

  List<UntisYear>? _schoolYears = <UntisYear>[];

  /// All [UntisYear]s of this school
  Future<List<UntisYear>> get schoolYears =>
      execAsyncFuncIfNull(_schoolYears, _fetchAndCacheMasterData);

  UntisTimeGrid? _timeGrid;

  /// A time grid, which reflects a table, which is the layout of the timetables
  Future<UntisTimeGrid> get timeGrid async =>
      _timeGrid ?? await _fetchAndCacheMasterData();

  /// Provides information about general information about the user
  Future<UntisStudentData> get studentData => getUserData();

  /// The latest time any variable from "masterData" was refreshed
  int masterDataTimestamp = 0;

  Future<UntisTimeGrid> _fetchAndCacheMasterData() async {
    final Map<String, dynamic> json =
        (await UserDataRequest(apiEndpoint, _auth).request())!;
    await _refreshMasterData(json['masterData']);
    // This thing returns timeGrid because this is always updated.
    // Additionally we need it to set a getter
    return _timeGrid!;
  }

  /// Updates cache from [masterData], it comes along userdata and timetable,
  /// this is resend if outdated (referring to [masterDataTimestamp])
  ///
  /// There needs to be a cache of subjects/classes/rooms etc.
  /// We can't get these from other requests, persisting [masterData] is needed.
  /// This object is sent with the [UserDataRequest] and [TimetableRequest].
  ///
  /// If a variable is null or empty, this is effectively automatically called
  Future<void> _refreshMasterData(Map<String, dynamic> masterData) async {
    // These are the only two values/objects which will exist on every fetch of masterData
    _timeGrid = UntisTimeGrid.fromJson(masterData['timeGrid']);
    masterDataTimestamp = masterData['timeStamp'];

    _absenceReasons = iterateFromJson(
            UntisAbsenceReason.fromJson, masterData['absenceReasons']) ??
        _absenceReasons;
    _duties =
        iterateFromJson(UntisDuty.fromJson, masterData['duties']) ?? _duties;
    _eventReasons = iterateFromJson(
            UntisEventReason.fromJson, masterData['eventReasons']) ??
        _eventReasons;
    _eventReasonGroups = iterateFromJson(
            UntisEventReasonGroup.fromJson, masterData['eventReasonGroups']) ??
        _eventReasonGroups;
    _excuseStates = iterateFromJson(
            UntisExcuseStatus.fromJson, masterData['excuseStatuses']) ??
        _excuseStates;
    _holidays =
        iterateFromJson(UntisHoliday.fromJson, masterData['holidays']) ??
            _holidays;
    _classes =
        iterateFromJson(UntisClass.fromJson, masterData['klassen']) ?? _classes;
    _rooms = iterateFromJson(UntisRoom.fromJson, masterData['rooms']) ?? _rooms;
    _subjects =
        iterateFromJson(UntisSubject.fromJson, masterData['subjects']) ??
            _subjects;
    _teachers =
        iterateFromJson(UntisTeacher.fromJson, masterData['teachers']) ??
            _teachers;
    _schoolYears =
        iterateFromJson(UntisYear.fromJson, masterData['schoolyears']) ??
            _schoolYears;
  }

  /// Get [UntisClass] from [id]
  ///
  Future<UntisClass?> getClassById(int id) async =>
      (await classes).where((UntisClass e) => e.id.id == id).firstOrNull;

  /// Get [UntisTeacher] from [id]
  Future<UntisTeacher?> getTeacherById(int id) async =>
      (await teachers).where((UntisTeacher e) => e.id.id == id).firstOrNull;

  /// Get [UntisSubject] from [id]
  Future<UntisSubject?> getSubjectById(int id) async =>
      (await subjects).where((UntisSubject e) => e.id.id == id).firstOrNull;

  /// Get [UntisRoom] from [id]
  Future<UntisRoom?> getRoomById(int id) async =>
      (await rooms).where((UntisRoom e) => e.id.id == id).firstOrNull;

  /// Gets the student, class, teacher, subject or room or returns null
  ///
  /// This method accepts [UntisElementDescriptor],
  /// as opposed to e.g. [getRoomById]
  Future<dynamic> getElementById(UntisElementDescriptor id) async {
    switch (id.type) {
      case UntisElementType.student:
        return studentData;
      case UntisElementType.classElement:
        return getClassById(id.id);
      case UntisElementType.teacher:
        return getTeacherById(id.id);
      case UntisElementType.subject:
        return getSubjectById(id.id);
      case UntisElementType.room:
        return getRoomById(id.id);
    }
  }
}
