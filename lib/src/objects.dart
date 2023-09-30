import 'package:equatable/equatable.dart';

import '../untis_mobile.dart';
import 'timetable_objects.dart';
import 'util.dart';

/// The types for common element ids
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

  /// Converts this to a json map
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'type': type.name, 'id': id};

  @override
  String toString() => toJson().toString();

  @override
  List<Object?> get props => <Object?>[type, id];
}

/// Gives information about the user itself
///
/// This can be his [username], real name([displayName]),
/// but also the student's [id] and [rights]
///
/// NOTE: Some fields in here are almost always null or empty lists,
/// I encountered [children], [departmentId] and [classIds] to not be used with my untis account at my school.
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

  final List<dynamic> classIds;
  final List<dynamic> rights;

  UntisStudentData.fromJson(Map<String, dynamic> json)
      : id = UntisElementDescriptor.fromJson(json),
        displayName = json['displayName'],
        username = json['schoolName'],
        departmentId = json['departmentId'],
        children = json['children'],
        classIds = json['klassenIds'],
        rights = json['rights'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'username': username,
        'departmentId': departmentId,
        'children': children,
        'klassenIds': classIds,
        'rights': rights
      };

  @override
  String toString() {
    return toJson().toString();
  }
}

class UntisAbsenceReason {
  final int id;
  final String name;
  final String longName;
  final bool active;

  /// Parses this object from [json]
  UntisAbsenceReason.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        active = json['active'];
}

class UntisDuty {
  final int id;
  final String name;
  final String longName;
  final String type;

  /// Parses this object from [json]
  UntisDuty.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        type = json['type'];
}

class UntisEventReason {
  final int id;
  final String name;
  final String longName;
  final UntisElementType elementType;
  final int groupId;
  final bool active;

  /// Parses this object from [json]
  UntisEventReason.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        elementType = UntisElementType.parse(json['elementType']),
        groupId = json['groupId'],
        active = json['active'];
}

class UntisEventReasonGroup {
  final int id;
  final String name;
  final String longName;
  final bool active;

  /// Parses this object from [json]
  UntisEventReasonGroup.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        active = json['active'];
}

class UntisExcuseStatus {
  final int id;
  final String name;
  final String longName;
  final bool excused;
  final bool active;

  /// Parses this object from [json]
  UntisExcuseStatus.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        excused = json['excused'],
        active = json['active'];
}

class UntisHoliday {
  final int id;
  final String name;
  final String longName;
  final DateTime startDate;
  final DateTime endDate;

  /// Parses this object from [json]
  UntisHoliday.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        startDate = untisDateToDateTime(json['startDate'])!,
        endDate = untisDateToDateTime(json['endDate'])!;
}

class UntisClass {
  final UntisElementDescriptor id;
  final String name;
  final String longName;
  final int departmentId;
  final DateTime startDate;
  final DateTime endDate;
  final String? foreColor;
  final String? backColor;
  final bool active;
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
        'longName': longName
      }.toString();
}

class UntisRoom {
  final UntisElementDescriptor id;
  final String name;
  final String longName;
  final int departmentId;
  final String? foreColor;
  final String? backColor;
  final bool active;
  final bool displayAllowed;

  UntisRoom.fromJson(Map<String, dynamic> json)
      : id = UntisElementDescriptor(UntisElementType.room, json['id']),
        name = json['name'],
        longName = json['longName'],
        departmentId = json['departmentId'],
        foreColor = json['foreColor'],
        backColor = json['backColor'],
        active = json['active'],
        displayAllowed = json['displayAllowed'];
}

class UntisSubject extends Equatable {
  final UntisElementDescriptor id;
  final String name;
  final String longName;

  /// This is unknown
  final List<dynamic> departmentIds;
  final String? foreColor;
  final String? backColor;
  final bool active;
  final bool displayAllowed;

  UntisSubject.fromJson(Map<String, dynamic> json)
      : id = UntisElementDescriptor(UntisElementType.subject, json['id']),
        name = json['name'],
        longName = json['longName'],
        departmentIds = json['departmentIds'],
        foreColor = json['foreColor'],
        backColor = json['backColor'],
        active = json['active'],
        displayAllowed = json['displayAllowed'];

  @override
  List<Object?> get props => <Object?>[id];
}

class UntisTeacher {
  final UntisElementDescriptor id;
  final String name;
  final String firstName;
  final String lastName;
  final List<dynamic> departmentIds;
  final String? foreColor;
  final String? backColor;
  final DateTime? entryDate;
  final DateTime? exitDate;
  final bool active;
  final bool displayAllowed;

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
}

class UntisYear {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  UntisYear.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        startDate = untisDateToDateTime(json['startDate'])!,
        endDate = untisDateToDateTime(json['endDate'])!;
}

/// These are basically a placeholder for the [UntisPeriod]s
///
/// This is essentially just a implementation without data,
/// to show when a period/lesson typically(according the [UntisTimeGrid]) starts or ends
class UntisDayUnit {
  final String label;
  final DateTime startTime;
  final DateTime endTime;

  UntisDayUnit.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        startTime = untisTimeToTimeOfDay(json['startTime'])!,
        endTime = untisTimeToTimeOfDay(json['endTime'])!;
}

/// This is a place holder for the rows in the grid
///
/// The [UntisDayUnit]s represent each day, so the columns
class UntisDay {
  final String dayLabel;

  /// Weekday using the constants(1-7) from DateTime
  ///
  /// Meaning,
  /// [DateTime.monday] is equal to [1] and
  /// [DateTime.sunday] is equal to [7]
  final int weekday;
  final List<UntisDayUnit> units;

  UntisDay.fromJson(Map<String, dynamic> json)
      : dayLabel = json['day'],
        weekday = untisWeekDayToDateTimeWeekDay(json['day']),
        units = List.from([
          for (Map<String, dynamic> dayUnit in json['units'])
            UntisDayUnit.fromJson(dayUnit)
        ]);
}

/// This is used for creating a table(layout) that accounts for breaks,
/// this is defined from the school
///
/// NOTE: [UntisTimeGrid] does not provide any data on which lessons/rooms/subjects there are,
/// please refer to [UntisTimetable] for that
class UntisTimeGrid {
  /// The actual days, this is usually the length 5 - Monday to Friday
  final List<UntisDay> days;

  UntisTimeGrid.fromJson(Map<String, dynamic> json)
      : days = <UntisDay>[
          for (Map<String, dynamic> day in json['days']) UntisDay.fromJson(day)
        ];
}

class UntisHomework {
  final int id;
  final int lessonId;
  final DateTime startDate;
  final DateTime endDate;
  final String text;

  /// Unknown what this is, always null?
  final dynamic remark;

  /// Indicates whether this homework has expired, because of reaching its [endDateTime]
  final bool completed;
  final List<dynamic> attachments;

  UntisHomework.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        lessonId = json['lessonId'],
        startDate = untisDateToDateTime(json['startDate'])!,
        endDate = untisDateToDateTime(json['endDate'])!,
        text = json['text'],
        remark = json['remark'],
        completed = json['completed'],
        attachments = json['attachments'];
}
