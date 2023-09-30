import 'dart:async';

import 'auth.dart';
import 'objects.dart';
import 'requests.dart';
import 'timetable_objects.dart';
import 'util.dart';

class UntisSession {
  final String apiEndpoint;
  final String username;

  late String _appSharedSecret;
  final String _password;

  UntisAuthentication get auth =>
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

  UntisSession._(String server, String school, this.username, this._password)
      : apiEndpoint = apiTemplate
      .replaceAll('%SRV%', server)
      .replaceAll('%SCHOOL%', school);

  /// The only way to construct a instance of UntisSession.
  ///
  /// The function uses [server], [school], [username] and [password] to
  /// set the API endpoint and login.
  static Future<UntisSession> init(String server, String school,
      String username, String password) async {
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
    (await UserDataRequest(apiEndpoint, auth).request())!;
    unawaited(_refreshMasterData(json['masterData']));
    _studentData = UntisStudentData.fromJson(json['userData']);
    return _studentData!;
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
  Future<UntisTimetable> getTimetable({UntisElementDescriptor? id,
    DateTime? startDate,
    DateTime? endDate}) async {
    startDate ??= DateTime.now();
    endDate ??= startDate.add(const Duration(days: 7));

    final TimetableRequest request = TimetableRequest(apiEndpoint, auth,
        id ?? (await studentData).id, _masterDataTimestamp, startDate, endDate);
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

  Future<List<UntisEventReason>> get eventReasons =>
      execAsyncFuncIfNull(_eventReasons, _fetchAndCacheMasterData);

  List<UntisEventReasonGroup>? _eventReasonGroups = <UntisEventReasonGroup>[];

  Future<List<UntisEventReasonGroup>> get eventReasonGroups =>
      execAsyncFuncIfNull(_eventReasonGroups, _fetchAndCacheMasterData);

  List<UntisExcuseStatus>? _excuseStates = <UntisExcuseStatus>[];

  /// Possible excuse states why you did not come to a lesson.
  ///
  /// This is most likely to be excused and
  Future<List<UntisExcuseStatus>> get excuseStates =>
      execAsyncFuncIfNull(_excuseStates, _fetchAndCacheMasterData);

  List<UntisHoliday>? _holidays = <UntisHoliday>[];

  Future<List<UntisHoliday>> get holidays =>
      execAsyncFuncIfNull(_holidays, _fetchAndCacheMasterData);

  List<UntisClass>? _classes = <UntisClass>[];

  Future<List<UntisClass>> get classes =>
      execAsyncFuncIfNull(_classes, _fetchAndCacheMasterData);

  List<UntisRoom>? _rooms = <UntisRoom>[];

  Future<List<UntisRoom>> get rooms =>
      execAsyncFuncIfNull(_rooms, _fetchAndCacheMasterData);

  List<UntisSubject>? _subjects = <UntisSubject>[];

  Future<List<UntisSubject>> get subjects =>
      execAsyncFuncIfNull(_subjects, _fetchAndCacheMasterData);

  List<UntisTeacher>? _teachers = <UntisTeacher>[];

  Future<List<UntisTeacher>> get teachers =>
      execAsyncFuncIfNull(_teachers, _fetchAndCacheMasterData);

  List<UntisYear>? _schoolYears = <UntisYear>[];

  Future<List<UntisYear>> get schoolYears =>
      execAsyncFuncIfNull(_schoolYears, _fetchAndCacheMasterData);

  UntisTimeGrid? _timeGrid;

  Future<UntisTimeGrid> get timeGrid async =>
      _timeGrid ?? await _fetchAndCacheMasterData();

  UntisStudentData? _studentData;

  Future<UntisStudentData> get studentData => getUserData();

  int _masterDataTimestamp = 0;

  Future<UntisTimeGrid> _fetchAndCacheMasterData() async {
    print("Refresh master data, because it was null");
    final Map<String, dynamic> json =
    (await UserDataRequest(apiEndpoint, auth).request())!;
    await _refreshMasterData(json['masterData']);
    // This thing returns timeGrid because this is always updated.
    // Additionally we need it to set a getter
    return _timeGrid!;
  }

  /// Updates cache from [masterData], it comes along userdata and timetable,
  /// this is resend if outdated (referring to [_masterDataTimestamp])
  ///
  /// There needs to be a cache of subjects/classes/rooms etc.
  /// We can't get these from other requests, persisting [masterData] is needed.
  /// This object is sent with the [UserDataRequest] and [TimetableRequest].
  ///
  /// If a variable is null or empty, this is effectively automatically called
  Future<void> _refreshMasterData(Map<String, dynamic> masterData) async {
    // These are the only two values/objects which will exist on every fetch of masterData
    _timeGrid = UntisTimeGrid.fromJson(masterData['timeGrid']);
    _masterDataTimestamp = masterData['timeStamp'];

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
      (await classes)
          .where((UntisClass e) => e.id.id == id)
          .firstOrNull;

  /// Get [UntisTeacher] from [id]
  Future<UntisTeacher?> getTeacherById(int id) async =>
      (await teachers)
          .where((UntisTeacher e) => e.id.id == id)
          .firstOrNull;

  /// Get [UntisSubject] from [id]
  Future<UntisSubject?> getSubjectById(int id) async =>
      (await subjects)
          .where((UntisSubject e) => e.id.id == id)
          .firstOrNull;

  /// Get [UntisRoom] from [id]
  Future<UntisRoom?> getRoomById(int id) async =>
      (await rooms)
          .where((UntisRoom e) => e.id.id == id)
          .firstOrNull;

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
