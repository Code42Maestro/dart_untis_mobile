import 'package:equatable/equatable.dart';

import 'session.dart';
import 'timetable_objects.dart';
import 'util.dart';

/// The types for common(!) element ids
enum UntisElementType {
  /// A student id. In my tests I need more rights to access other students
  student('STUDENT'),

  /// Id type for [UntisClass]
  classElement('CLASS'),

  /// Id type for [UntisTeacher]
  teacher('TEACHER'),

  /// Id type for [UntisSubject]
  subject('SUBJECT'),

  /// Id type for [UntisRoom]
  room('ROOM');

  /// The untis name for this element
  final String name;

  const UntisElementType(this.name);

  /// Parses the untis name of an [UntisElementType] to
  /// the actual [UntisElementType]
  static UntisElementType parse(String typeName) {
    return UntisElementType.values
        .firstWhere((UntisElementType element) => element.name == typeName);
  }
}

/// Used to describe common elements of the API
class UntisElementDescriptor extends Equatable {
  /// The type of this descriptor, for example class
  final UntisElementType type;

  /// The actual id as a number
  final int id;

  /// Constructs new instance with [type] and [id]
  const UntisElementDescriptor(this.type, this.id);

  /// Constructs new instance from json
  UntisElementDescriptor.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? json['elemId'],
        type = UntisElementType.parse(json['name'] ?? json['elemType']);

  @override
  String toString() =>
      <String, dynamic>{'type': type.name, 'id': id}.toString();

  @override
  List<Object?> get props => <Object?>[type, id];
}

/// Gives information about the user itself
///
/// This can be his [username], real name([displayName]),
/// but also the student's [id] and [rights]
///
/// NOTE: Some fields in here are almost always null or empty lists,
/// I encountered [children], [departmentId] and [classIds] to not be used
/// with my untis account at my school.
class UntisStudentData {
  /// The id of the student at this school
  final UntisElementDescriptor id;

  /// The full name of the student
  ///
  /// This may be different depending on school.
  /// Maybe this is just the last name, but I only encountered the full name.
  final String displayName;

  /// Returns the username, which was also used to login
  final String username;

  /// Probably represents the "department", where the user is in.
  ///
  /// In my testing this was always 0, but I could imagine that some teachers,
  /// could have something else. There may be a admin department?
  final int departmentId;

  /// With my testing accounts this was always []
  ///
  /// This maybe could be used for teacher, to connect them with their kids
  final List<dynamic> children;

  /// Unknown what this is, always []?
  final List<dynamic> classIds;

  /// An overview of the rights, that a user has
  final List<dynamic> rights;

  /// Parses this object from [json]
  UntisStudentData.fromJson(Map<String, dynamic> json)
      : id = UntisElementDescriptor.fromJson(json),
        displayName = json['displayName'],
        username = json['schoolName'],
        departmentId = json['departmentId'],
        children = json['children'],
        classIds = json['klassenIds'],
        rights = json['rights'];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'displayName': displayName,
        'username': username,
        'departmentId': departmentId,
        'children': children,
        'classIds': classIds,
        'rights': rights
      }.toString();
}

/// Don't know how to actually use this, but his should represent, which task
/// roles there are for a class.
/// The data behind these duties can be accessed with the WebUntis API
///
/// For example, cleaning, class boss and former class boss
class UntisDuty {
  /// The id for the individual [UntisDuty], which may be referred to
  /// from other teacher functions
  final int id;

  /// A short name, for example "CS"
  final String name;

  /// The (mostly) written out name, for example "cleaning service"
  final String longName;

  /// The different duty types.
  ///
  /// I encountered there to be 3, STEWARD, PREFECT and PREFECT_SUBST
  final String type;

  /// Parses this object from [json]
  UntisDuty.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        type = json['type'];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'longName': longName,
        'type': type,
      }.toString();
}

/// Don't know how this is used, but it can be a reason for either a student or
/// a class.
///
/// A few examples are for students, active participation,
/// passive participation, no homework, no sport clothes and no working material
///
/// For the whole class there are these, instruction(indoctrination) or the
/// messaging of the current grades.
class UntisEventReason {
  /// The id for the individual [UntisEventReason], which may be referred to
  /// from other teacher functions
  final int id;

  /// Short form of [longName], for example "No HW"
  final String name;

  /// The name of the event reason, for example "No homeworks"
  final String longName;

  /// What type of event reason this is, either for students or a class
  final UntisElementType elementType;

  /// This groupId, refers to [UntisEventReasonGroup], this is basically
  /// the type
  final int groupId;

  /// Whether this event reason is still in use
  final bool active;

  /// Parses this object from [json]
  UntisEventReason.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        elementType = UntisElementType.parse(json['elementType']),
        groupId = json['groupId'],
        active = json['active'];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'longName': longName,
        'elementType': elementType.name,
        'groupId': groupId,
        'active': active,
      }.toString();
}

/// The different "types" of event reasons (whatever event reasons are), used by
/// [UntisEventReason]
///
/// These are usually, notice, participation in sports and material and homework
class UntisEventReasonGroup {
  /// The id for the individual [UntisEventReasonGroup], to refer to from
  /// [UntisEventReason]. This is usually 1, 2 or 3
  final int id;

  /// The short name of a group, for example "Material / HW"
  final String name;

  /// The written out name, for example "Materials, homeworks"
  final String longName;

  /// Whether this event reason group is still in use
  final bool active;

  /// Parses this object from [json]
  UntisEventReasonGroup.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        active = json['active'];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'longName': longName,
        'active': active,
      }.toString();
}

/// A time period, where you don't have school
class UntisHoliday {
  /// The id of the individual [UntisHoliday]
  final int id;

  /// A name that is not visible in the app(?)
  final String name;

  /// The name that really counts, e.g. winter holidays, christmas holidays...
  final String longName;

  /// The start date, of the school-less period
  final DateTime startDate;

  /// The end date, of the school-less period
  final DateTime endDate;

  /// Parses this object from [json]
  UntisHoliday.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        startDate = untisDateToDateTime(json['startDate'])!,
        endDate = untisDateToDateTime(json['endDate'])!;

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'longName': longName,
        'startDate': startDate,
        'endDate': endDate
      }.toString();
}

/// A school class
class UntisClass {
  /// The id of the individual [UntisHoliday]
  final UntisElementDescriptor id;

  /// The short name, e.g. 6/2 or 8c
  final String name;

  /// Most of the times, the class teacher(s) name(s)
  final String longName;

  /// Probably represents the "department", where the class is in.
  ///
  /// In my testing this was always 0.
  final int departmentId;

  /// The starting date, where this class is going to "start" or be valid
  final DateTime startDate;

  /// The end date, where this class is going to be invalid.
  /// Usually 10 months after [startDate], because of holidays
  final DateTime endDate;

  /// The foreground color, always null?
  final String? foreColor;

  /// The background color, always null?
  final String? backColor;

  /// Whether this class is active or in use, always true?
  final bool active;

  /// Whether the timetable of this class can be accessed from the user
  final bool displayable;

  /// Parses this object from [json]
  UntisClass.fromJson(Map<String, dynamic> json)
      : id = UntisElementDescriptor(UntisElementType.classElement, json['id']),
        name = json['name'],
        longName = json['longName'],
        departmentId = json['departmentId'],
        startDate = untisDateToDateTime(json['startDate'])!,
        // Just hope this above is never null lol
        endDate = untisDateToDateTime(json['endDate'])!,
        // Just hope this is above never null lol
        foreColor = json['foreColor'],
        backColor = json['backColor'],
        active = json['active'],
        displayable = json['displayable'];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'longName': longName,
        'departmentId': departmentId,
        'foreColor': foreColor,
        'startDate': startDate,
        'endDate': endDate,
        'backColor': backColor,
        'active': active,
        'displayable': displayable,
      }.toString();
}

/// A class/school room
class UntisRoom {
  /// The id of the individual [UntisRoom]
  final UntisElementDescriptor id;

  /// Usually the room number in the school, e.g. 2.003 or 2.03
  final String name;

  /// The title of the room, which class/subject/activity is using this.
  final String longName;

  /// Probably represents the "department", where this room is part of.
  ///
  /// In my testing this was always 0.
  final int departmentId;

  /// The foreground color, always null?
  final String? foreColor;

  /// The background color, always null?
  final String? backColor;

  /// Whether this (label of a) room is still in use. Usually set to false when
  /// the naming scheme was changed and the old rooms where not deleted.
  final bool active;

  /// Probably reserved for teachers, whether this user is allowed to see which
  /// person is using this room at a specific time
  final bool displayAllowed;

  /// Parses this object from [json]
  UntisRoom.fromJson(Map<String, dynamic> json)
      : id = UntisElementDescriptor(UntisElementType.room, json['id']),
        name = json['name'],
        longName = json['longName'],
        departmentId = json['departmentId'],
        foreColor = json['foreColor'],
        backColor = json['backColor'],
        active = json['active'],
        displayAllowed = json['displayAllowed'];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'longName': longName,
        'departmentId': departmentId,
        'foreColor': foreColor,
        'backColor': backColor,
        'active': active,
        'displayAllowed': displayAllowed,
      }.toString();
}

/// A school subject
class UntisSubject extends Equatable {
  /// The id of the individual [UntisSubject]
  final UntisElementDescriptor id;

  /// The short name of a subject, for example Ma
  final String name;

  /// The written out name, for example Mathematics
  final String longName;

  /// Probably represents the "departments", which have this subject.
  ///
  /// In my testing this was always []
  final List<dynamic> departmentIds;

  /// The foreground color, which is actually used for displaying the
  /// text of a subject
  final int? foreColorValue;

  /// The background color, which is actually used for displaying,
  /// for what is around the text
  final int? backColorValue;

  /// Whether this subject is currently used or not, usually used, when there
  /// is need of replacing of a subject.
  final bool active;

  /// Probably reserved for teachers, whether this user is allowed to see which
  /// teachers are teaching this subject.
  final bool displayAllowed;

  /// Parses this object from [json]
  UntisSubject.fromJson(Map<String, dynamic> json)
      : id = UntisElementDescriptor(UntisElementType.subject, json['id']),
        name = json['name'],
        longName = json['longName'],
        departmentIds = json['departmentIds'],
        foreColorValue = json['foreColor'] != null
            ? colorValueFromHex(json['foreColor'])
            : null,
        backColorValue = json['backColor'] != null
            ? colorValueFromHex(json['backColor'])
            : null,
        active = json['active'],
        displayAllowed = json['displayAllowed'];

  @override
  List<Object?> get props => <Object?>[id];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'longName': longName,
        'departmentIds': departmentIds,
        'foreColor': foreColorValue,
        'backColor': backColorValue,
        'active': active,
        'displayAllowed': displayAllowed,
      }.toString();
}

/// A school teacher
class UntisTeacher {
  /// The id of the individual [UntisTeacher]
  final UntisElementDescriptor id;

  /// The short name of a teacher, e.g. Mue
  final String name;

  /// The first name of a teacher, e.g. Max
  final String firstName;

  /// The last name of a teacher, e.g. Mueller
  final String lastName;

  /// The combination of [firstName] and [lastName]
  String get fullName => '$firstName $lastName';

  /// Probably represents the "departments", which this teacher is in.
  ///
  /// In my testing this was always []
  final List<dynamic> departmentIds;

  /// The foreground color, always null?
  final String? foreColor;

  /// The foreground color, always null?
  final String? backColor;

  /// When this teacher "entered" the school
  final DateTime? entryDate;

  /// When this teacher left the school
  final DateTime? exitDate;

  /// Either this teacher is not real or when [exitDate] is defined,
  /// the teacher left.
  final bool active;

  /// Probably reserved for teachers/admins, whether this user is allowed to see
  /// the subjects a teacher is teaching.
  final bool displayAllowed;

  /// Parses this object from [json]
  UntisTeacher.fromJson(Map<String, dynamic> json)
      : id = UntisElementDescriptor(UntisElementType.teacher, json['id']),
        name = json['name'],
        firstName = json['firstName'],
        lastName = json['lastName'],
        departmentIds = json['departmentIds'],
        foreColor = json['foreColor'],
        backColor = json['backColor'],
        entryDate = untisDateToDateTime(json['entryDate']),
        exitDate = untisDateToDateTime(json['exitDate']),
        active = json['active'],
        displayAllowed = json['displayAllowed'];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'firstName': firstName,
        'lastName': lastName,
        'departmentIds': departmentIds,
        'foreColor': foreColor,
        'backColor': backColor,
        'entryDate': entryDate,
        'exitDate': exitDate,
        'active': active,
        'displayAllowed': displayAllowed,
      }.toString();
}

/// A school year
class UntisYear {
  /// The id of the individual [UntisYear]
  final int id;

  /// The name of a year, e.g. 2017/2018
  final String name;

  /// The beginning of the school year, usually directly after summer holiday
  final DateTime startDate;

  /// The end of the school year, usually directly before summer holiday
  final DateTime endDate;

  /// Parses this object from [json]
  UntisYear.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        startDate = untisDateToDateTime(json['startDate'])!,
        endDate = untisDateToDateTime(json['endDate'])!;

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
      }.toString();
}

/// These are basically a placeholder for the [UntisPeriod]s
///
/// This is essentially just a implementation without data,
/// to show when a period/lesson typically(according the [UntisTimeGrid]) starts or ends
class UntisDayUnit {
  /// Don't know what this is used for
  final String label;

  /// The beginning time of a lesson
  final DateTime startTime;

  /// The ending time of a lesson
  final DateTime endTime;

  /// Parses this object from [json]
  UntisDayUnit.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        startTime = untisTimeToTimeOfDay(json['startTime'])!,
        endTime = untisTimeToTimeOfDay(json['endTime'])!;

  @override
  String toString() => <String, dynamic>{
        'label': label,
        'startTime': startTime,
        'endTime': endTime,
      }.toString();
}

/// This is a place holder for the rows in the grid
///
/// The [UntisDayUnit]s represent each day, so the columns
class UntisDay {
  /// Weekday in format of "MON", "TUE"...
  final String dayLabel;

  /// Weekday using the constants(1-7) from DateTime
  ///
  /// Meaning,
  /// [DateTime.monday] is equal to [1] and
  /// [DateTime.sunday] is equal to [7]
  final int weekday;

  /// The units or lesson placeholder on this day
  final List<UntisDayUnit> units;

  /// Parses this object from [json]
  UntisDay.fromJson(Map<String, dynamic> json)
      : dayLabel = json['day'],
        weekday = untisWeekDayToDateTimeWeekDay(json['day']),
        units = <UntisDayUnit>[
          for (Map<String, dynamic> dayUnit in json['units'])
            UntisDayUnit.fromJson(dayUnit)
        ];

  @override
  String toString() => <String, dynamic>{
        'dayLabel': dayLabel,
        'weekday': weekday,
        'units': units,
      }.toString();
}

/// This is used for creating a table(layout) that accounts for breaks,
/// this is defined from the school
///
/// NOTE: [UntisTimeGrid] does not provide any data on which lessons/rooms/subjects there are,
/// please refer to [UntisTimetable] for that
class UntisTimeGrid {
  /// The actual days, this is usually the length 5 - Monday to Friday
  final List<UntisDay> days;

  /// Parses this object from [json]
  UntisTimeGrid.fromJson(Map<String, dynamic> json)
      : days = <UntisDay>[
          for (Map<String, dynamic> day in json['days']) UntisDay.fromJson(day)
        ];

  @override
  String toString() => <String, dynamic>{'days': days}.toString();
}

/// A homework, that can be contained in a [UntisPeriod] or be found directly
/// with the adequate method in [UntisSession]
class UntisHomework {
  /// The id of the individual [UntisHomework]
  final int id;

  /// The period, where this homework should be shown
  /// (where the homeworks elapses).
  ///
  /// This can be null, because the [lessonId] was not "fetched to a period"
  // TODO(Code42Maestro): Establish the fetching of this
  final UntisPeriod? period;

  /// The lesson id, this can be then correlated to a period
  final int lessonId;

  /// When this homework should be active,
  /// (maybe also when its visible to students)
  final DateTime startDate;

  /// The end date, when it should elapse
  final DateTime endDate;

  /// The actual task
  final String text;

  /// Unknown what this is, always null?
  final dynamic remark;

  /// Indicates whether this homework has expired, because of reaching its
  /// [endDate]
  final bool completed;

  /// Attachments, I never encountered this, so always []?
  final List<dynamic> attachments;

  /// Parses this object from [json]
  UntisHomework.fromJson(Map<String, dynamic> json, [this.period])
      : id = json['id'],
        lessonId = json['lessonId'],
        startDate = untisDateToDateTime(json['startDate'])!,
        endDate = untisDateToDateTime(json['endDate'])!,
        text = json['text'],
        remark = json['remark'],
        completed = json['completed'],
        attachments = json['attachments'];

  @override
  String toString() => <String, dynamic>{
        'id': id,
        'lessonId': lessonId,
        'period': period,
        'startDate': startDate,
        'endDate': endDate,
        'text': text,
        'remark': remark,
        'completed': completed,
        'attachments': attachments
      }.toString();
}

// TODO(Code42Maestro): Implement UntisExam
/// A school exam, which can be written from more than one class
class UntisExam {
  /// The id of an individual [UntisExam]
  final int id;

  /// Parses this object from [json]
  UntisExam.fromJson(Map<String, dynamic> json) : id = json['id'];
}
