import 'objects.dart';
import 'session.dart';
import 'util.dart';

/// This text object is mostly used when period is irregular.
/// It then delivers general information about the period
///
/// This is can include the period title. Furthermore it can include notes
/// from the teacher. It is also used to describe the name of e.g. a class trip
class UntisPeriodText {
  /// This used for a title, when period is a irregular lesson
  ///
  /// If this period represents a class trip,
  /// this [lesson] string would most likely be "class trip"
  final String lesson;

  /// This text is used as a substitute text
  ///
  /// If a teacher is not there and this is the replacement period,
  /// this is probably set to a description what you are doing instead.
  final String substitution;

  /// General notes from the teacher for this period
  final String notes;

  /// Unknown what this is, always null?
  final List<dynamic> attachments;

  /// Parses this object from [json]
  UntisPeriodText.fromJson(Map<String, dynamic> json)
      : lesson = json['lesson'],
        substitution = json['substitution'],
        notes = json['info'],
        attachments = json['attachments'];

  @override
  String toString() => <String, dynamic>{
        'lesson': lesson,
        'substitution': substitution,
        'notes': notes,
        'attachments': attachments
      }.toString();
}

/// States of lessons, which determine the fit in the timetable
enum UntisPeriodState {
  /// This likely means that the period is a "normal" planned lesson
  regular,

  /// This is a new period on top of the regular timetable e.g. a class trip
  irregular,

  /// this period is cancelled
  cancelled;

  /// Parses the name of an enum to the actual enum
  static UntisPeriodState parse(String typeName) {
    if(typeName.toLowerCase() == "regular") {
      return UntisPeriodState.regular;
    } else if(typeName.toLowerCase() == "irregular") {
      return UntisPeriodState.irregular;
    } else if(typeName.toLowerCase() == "cancelled") {
      return UntisPeriodState.cancelled;
    }
    return UntisPeriodState.regular;
  }

  @override
  String toString() => name;
}

/// This can be a lesson, a class trip or in general a part of the timetable
class UntisPeriod {
  /// Defines the id of the period, so at this point in time
  final int id;

  /// Defines the planned lesson
  ///
  /// This lessonId describes basically, look this is lesson English with Mrs. Mueller and class 11/3
  final int lessonId;

  /// Starting date and time for this period
  final DateTime startDateTime;

  /// Starting date and time for this period
  final DateTime endDateTime;

  /// Foreground color of this period
  ///
  /// This is probably not the real color, refer to the subject colors
  final int foreColorValue;

  /// Background color of this period
  ///
  /// This is probably not the real color, refer to the subject colors
  final int backColorValue;

  /// Unknown use, maybe always null?
  final int innerForeColorValue;

  /// Unknown use, maybe always null?
  final int innerBackColorValue;

  /// This text object is mostly used when period [isIrregular].
  /// It then delivers general information about the period
  ///
  /// This is can include the period title. Furthermore it can include notes
  /// from the teacher. This is also used to describe the name
  /// of e.g. a class trip.
  final UntisPeriodText text;

  /// This is the list of regular planned class(es) in this period
  ///
  /// If a class is on a class trip and can not participate in this course,
  /// this will still hold the class.
  ///
  /// NOTE: If period [isCancelled] this doesn't really matter anymore,
  /// as the classes are not taken out most of the times
  /// Refer to [classes] if you want the classes, who actually are there then.
  final List<UntisClass> planClasses = <UntisClass>[];

  /// This is a list of actual class(es) in this period
  ///
  /// If a class is on a class trip , [classes] will hold the classes,
  /// that are actually participating in this period.
  ///
  /// NOTE: If period [isCancelled] this doesn't really matter anymore,
  /// as the classes are not taken out most of the times
  /// Refer to [planClasses], to get only the ones that are regularly there
  final List<UntisClass> classes = <UntisClass>[];

  /// This is the list of regular planned teacher(s) in this period
  ///
  /// If a teacher gets replaced from the planned organized period,
  /// this will still hold the old(maybe ill) teacher.
  ///
  /// Refer to [teachers] if you want the teachers, who actually are there then.
  final List<UntisTeacher> planTeachers = <UntisTeacher>[];

  /// This is a list of actual teacher(s) in this period
  ///
  /// If a teacher is ill and gets replaced by another one,
  /// this will hold the teacher, that replaces the old one
  ///
  /// Refer to [planTeachers], to get only those that would be regularly there
  final List<UntisTeacher> teachers = <UntisTeacher>[];

  /// The first object of [teachers] or null
  late final UntisTeacher? teacher;

  /// This is the list of regular planned teacher(s) in this period
  ///
  /// Don't know when just the subject gets replaced,
  /// but this would still hold the old subject.
  ///
  /// Refer to [subjects] if you want the subject, who is actually there then.
  final List<UntisSubject> planSubjects = <UntisSubject>[];

  /// This is a list of actual subject(s) in this period
  ///
  /// Don't know when just the subject gets replaced,
  /// but this will hold the actual subject, that will be there then.
  ///
  /// Refer to [planSubjects], to get only the subject that would be planned
  final List<UntisSubject> subjects = <UntisSubject>[];

  /// The first object of [subjects] or null
  late final UntisSubject? subject;

  /// This is a list of the regular planned room(s) in this period
  ///
  /// If the room is moved, this will still hold the old room.
  /// If no room is moved [planRooms] is the same as [rooms]
  ///
  /// Refer to [teachers] if you want the new room.
  final List<UntisRoom> planRooms = <UntisRoom>[];

  /// This is a list of the actual room(s) in this period
  ///
  /// If the room is moved, [rooms] will hold the new one,
  /// that replaces the old one.
  /// If no room is moved [rooms] is the same as [planRooms]
  ///
  /// Refer to [planRooms], to get only the room that was planned
  final List<UntisRoom> rooms = <UntisRoom>[];

  /// The first object of [rooms] or null
  late final UntisRoom? room;

  /// A enumeration of strings that correspond to rights
  final List<dynamic> rights;

  /// Defines whether this lesson has a normal structure
  /// Rather use [isCancelled], [isRegular] and [isIrregular]
  ///
  /// REGULAR means it has a subject element
  /// IRREGULAR is a new period e.g, a trip on top of the regular timetable.
  /// CANCELLED means what the names says
  final List<UntisPeriodState> states;

  /// Whether this period is cancelled (not occurring)
  ///
  /// Does [states] contain a cancelled object
  bool get isCancelled => states.contains(UntisPeriodState.cancelled);

  /// Whether this period is regular (not a e.g. class trip)
  ///
  /// Does [states] contain regular
  bool get isRegular => states.contains(UntisPeriodState.regular);

  /// Whether this period is irregular (a class trip)
  ///
  /// Does [states] contain irregular
  bool get isIrregular => states.contains(UntisPeriodState.irregular);

  /// The list of homeworks, that are specified from the teacher
  final List<UntisHomework> homeworks;

  /// Unknown what this is, always null?
  final dynamic messengerChannel;

  /// Unknown what this is, always null?
  // TODO(Code42Maestro): Implement [UntisExam] here
  final dynamic exam;

  /// Unknown what this is, always false?
  final bool isOnlinePeriod;

  /// Hash for indicating a consecutive period/a block. A lesson block is for example two consecutive lessons
  ///
  /// E.g. If one has two math lessons, they will have the same [blockHash]
  /// But if another class member has two spanish lessons there,
  /// these two will have a different [blockHash] than maths
  ///
  /// This is not necessarily connected with the same [lessonId]
  /// If two lessons have the same [lessonId], they don't necessarily have
  /// the same [blockHash]
  final int blockHash;

  UntisPeriod._(
      this.id,
      this.lessonId,
      this.startDateTime,
      this.endDateTime,
      this.foreColorValue,
      this.backColorValue,
      this.innerForeColorValue,
      this.innerBackColorValue,
      this.text,
      this.rights,
      this.states,
      this.homeworks,
      this.messengerChannel,
      this.exam,
      this.isOnlinePeriod,
      this.blockHash);

  static Future<void> _setElementFields<T>(
      Iterable<dynamic> json,
      Future<T?> Function(int) getElementFromId,
      List<T> planField,
      List<T> field) {
    planField.clear();
    final Iterable<int> pIds =
        json.map((dynamic e) => (e as Map<String, dynamic>)['orgId']);
    final Future<List<void>> planFieldFuture = Future.wait(
        pIds.map((int id) => getElementFromId(id).then((T? element) {
              // Is this even necessary? Because this should not be null
              if (element != null) planField.add(element);
            })));

    field.clear();
    final Iterable<int> ids =
        json.map((dynamic e) => (e as Map<String, dynamic>)['id']);
    final Future<List<void>> fieldFuture =
        Future.wait(ids.map((int id) => getElementFromId(id).then((T? element) {
              // Is this even necessary? Because this should not be null
              if (element != null) field.add(element);
            })));
    return Future.wait(<Future<List<void>>>[planFieldFuture, fieldFuture]);
  }

  /// Parses this object from [json]
  ///
  /// This class needs [UntisSession] to fetch the ids for class/teachers/rooms/subjects
  static Future<UntisPeriod> fromJson(
      UntisSession s, Map<String, dynamic> json) async {
    final UntisPeriod p = UntisPeriod._(
        json['id'],
        json['lessonId'],
        untisDateTimeToDateTime(json['startDateTime'])!,
        untisDateTimeToDateTime(json['endDateTime'])!,
        colorValueFromHex(json['foreColor']),
        colorValueFromHex(json['backColor']),
        colorValueFromHex(json['innerForeColor']),
        colorValueFromHex(json['innerBackColor']),
        UntisPeriodText.fromJson(json['text']),
        json['can'],
        <UntisPeriodState>[
          for (final String state in json['is']) UntisPeriodState.parse(state)
        ],
        <UntisHomework>[
          for (final Map<String, dynamic> entry in json['homeWorks'])
            UntisHomework.fromJson(entry)
        ],
        json['messengerChannel'],
        json['exam'],
        json['isOnlinePeriod'],
        json['blockHash']);

    final Iterable<Map<String, dynamic>> classElements =
        List<Map<String, dynamic>>.from(json['elements'])
            .where((Map<String, dynamic> e) => e['type'] == 'CLASS');

    final Future<void> classFuture = _setElementFields(
        classElements, s.getClassById, p.planClasses, p.classes);

    final Iterable<Map<String, dynamic>> teacherElements =
        List<Map<String, dynamic>>.from(json['elements'])
            .where((Map<String, dynamic> e) => e['type'] == 'TEACHER');
    final Future<void> teacherFuture = _setElementFields(
        teacherElements, s.getTeacherById, p.planTeachers, p.teachers);

    final Iterable<Map<String, dynamic>> subjectElements =
        List<Map<String, dynamic>>.from(json['elements'])
            .where((Map<String, dynamic> e) => e['type'] == 'SUBJECT');
    final Future<void> subjectFuture = _setElementFields(
        subjectElements, s.getSubjectById, p.planSubjects, p.subjects);

    final Iterable<Map<String, dynamic>> roomElements =
        List<Map<String, dynamic>>.from(json['elements'])
            .where((Map<String, dynamic> e) => e['type'] == 'ROOM');
    final Future<void> roomFuture =
        _setElementFields(roomElements, s.getRoomById, p.planRooms, p.rooms);
    // Run in parallel to speed up parsing, now we wait for all to finish
    await Future.wait(
        <Future<void>>[classFuture, teacherFuture, subjectFuture, roomFuture]);
    p.teacher = p.teachers.firstOrNull;
    p.subject = p.subjects.firstOrNull;
    p.room = p.rooms.firstOrNull;
    return p;
  }

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'lessonId': lessonId,
        'startDateTime': startDateTime,
        'endDateTime': endDateTime,
        'classes': classes,
        'teachers': subjects,
        'subjects': subjects,
        'rooms': rooms,
        'foreColor': foreColorValue,
        'backColor': backColorValue,
        'innerForeColor': innerForeColorValue,
        'innerBackColor': innerBackColorValue,
        'text': text,
        'rights': rights,
        'states': states,
        'homeworks': homeworks,
        'messengerChannel': messengerChannel,
        'exam': exam,
        'isOnlinePeriod': isOnlinePeriod,
        'blockHash': blockHash
      }.toString();
}

/// Timetable object containing [periods].
///
/// Additionally the [displayableStartDate] and [displayableEndDate]
class UntisTimetable {
  /// The start date from where there are lessons
  final DateTime displayableStartDate;

  /// The ending date where there aren't lessons anymore
  ///
  /// This is ideally the endDate of [UntisSession#getTimetable]
  final DateTime displayableEndDate;

  /// The actual periods(lessons/lesson blocks) grouped by day
  ///
  /// This start algorithm start always on the first days of the [grid]
  // TODO(Code42Maestro): Fix this /\
  List<List<UntisPeriod?>> groupedPeriods(UntisTimeGrid grid) {
    final List<List<UntisPeriod?>> groupedPeriods = <List<UntisPeriod?>>[];

    for (final UntisDay day in grid.days) {
      final int weekday = day.weekday;
      final Iterable<UntisPeriod> immutablePeriods =
          periods.where((UntisPeriod e) => e.startDateTime.weekday == weekday);
      final List<UntisPeriod?> dailyPeriods = <UntisPeriod?>[];
      for (final UntisDayUnit unit in day.units) {
        dailyPeriods.add(immutablePeriods
            .where((UntisPeriod p) =>
                p.startDateTime.copyWithHHM() == unit.startTime.copyWithHHM())
            .firstOrNull);
      }

      groupedPeriods.add(dailyPeriods);
    }
    return groupedPeriods;
  }

  /// The actual periods(lessons/lesson blocks) just sorted by startDate
  final List<UntisPeriod> periods;

  UntisTimetable._(
      this.displayableStartDate, this.displayableEndDate, this.periods);

  /// Parses this object from [json]
  ///
  /// This method needs [UntisSession] to pass it to [UntisPeriod.fromJson]
  static Future<UntisTimetable> fromJson(
      UntisSession s, Map<String, dynamic> json) async {
    final List<UntisPeriod> allPeriods =
        await Future.wait(<Future<UntisPeriod>>[
      for (final Map<String, dynamic> period in json['periods'])
        UntisPeriod.fromJson(s, period)
    ]);
    allPeriods.sort((UntisPeriod a, UntisPeriod b) =>
        a.startDateTime.compareTo(b.startDateTime));

    return UntisTimetable._(untisDateToDateTime(json['displayableStartDate'])!,
        untisDateToDateTime(json['displayableEndDate'])!, allPeriods);
  }

  @override
  String toString() => <String, dynamic>{
        'displayableStartDate': displayableStartDate,
        'displayableEndDate': displayableEndDate,
        'periods': periods
      }.toString();
}
