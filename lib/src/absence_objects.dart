import '../dart_untis_mobile.dart';
import 'util.dart';

/// The actual excuse for an [UntisAbsence], it contains a reference
/// to a [UntisExcuseStatus].
class UntisExcuse {
  /// ID to track this individual excuse
  final int id;

  /// The (not-)excuse type
  final UntisExcuseStatus excuseStatus;

  /// An optional title
  final String text;

  /// Unknown, but maybe the amount how often this was used?
  final int number;

  /// The date for when this excuse is valid
  final DateTime date;

  UntisExcuse._(this.id, this.excuseStatus, this.text, this.number, this.date);

  /// Parses this object from [json]
  static Future<UntisExcuse> fromJson(
      UntisSession s, Map<String, dynamic> json) async {
    final UntisExcuseStatus excuseStatus = (await s.excuseStates).firstWhere(
        (UntisExcuseStatus state) => state.id == json['excuseStatusId']);
    return UntisExcuse._(json['id'], excuseStatus, json['text'], json['number'],
        untisDateToDateTime(json['date'])!);
  }
}

/// Analogy to [UntisAbsence] and [UntisAbsenceReason]. This is [UntisExcuse]
/// and [UntisExcuseStatus].
///
/// Examples for this are, plain up excused, plain up not excused,
/// not accepted (and not excused) and a delay (that is excused)
///
/// This is a general status, that can be used with every [UntisExcuse].
/// [UntisExcuse] is the concrete excuse, which contains a reference to this
class UntisExcuseStatus {
  /// ID for referred to from a [UntisExcuse]
  final int id;

  /// Shorter form of [longName], most of the times a verb
  final String name;

  /// The written out form of [name], most of the times a substantive
  final String longName;

  /// Whether this status counts as excused
  final bool excused;

  /// Unknown what this is, always true?
  final bool active;

  /// Parses this object from [json]
  UntisExcuseStatus.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        excused = json['excused'],
        active = json['active'];
}

/// An absence of a student
///
/// Contains a field whether student is excused and if so, in which way.
/// Additionally contains [UntisAbsenceReason] and sometimes a title,
/// for example for a school event.
class UntisAbsence {
  /// ID for the individual absence
  final int id;

  /// The id of the student(, for some reason)
  final UntisElementDescriptor studentId;

  /// This is always -1 with my testing
  final UntisElementDescriptor classId;

  /// The date and time of the beginning of the absence
  final DateTime startDateTime;

  /// The date and time of the ending of the absence
  final DateTime endDateTime;

  /// Unknown what this is, always false?
  final bool owner;

  /// Whether this absence is excused
  final bool excused;

  /// The excuse itself. This can be null if the excuse is yet to be filled out.
  final UntisExcuse? excuse;

  /// The reason why the student is not there
  final UntisAbsenceReason reason;

  /// An optional title for the absence reason(, seems a bit unnecessary)
  final String reasonText;

  /// A title for the absence, for example the title of a school event
  final String text;

  UntisAbsence._(
      this.id,
      this.studentId,
      this.classId,
      this.startDateTime,
      this.endDateTime,
      this.owner,
      this.excused,
      this.excuse,
      this.reason,
      this.reasonText,
      this.text);

  /// Parses this object from [json]
  static Future<UntisAbsence> fromJson(
      UntisSession s, Map<String, dynamic> json) async {
    final UntisExcuse? excuse = json['excused'] != null
        ? await UntisExcuse.fromJson(s, json['excused'])
        : null;
    final UntisAbsenceReason absenceReason = (await s.absenceReasons)
        .firstWhere(
            (UntisAbsenceReason state) => state.id == json['absenceReasonId']);
    return UntisAbsence._(
        json['id'],
        json['studentId'],
        json['klasseId'],
        untisDateTimeToDateTime(json['startDateTime'])!,
        untisDateTimeToDateTime(json['endDateTime'])!,
        json['owner'],
        json['excused'],
        excuse,
        absenceReason,
        json['absenceReason'],
        json['text']);
  }
}

/// Reasons for an absence. Part of an [UntisAbsence]
///
/// This can be illness, school event, furlough(granted vacation), delay
/// This is a necessity for [UntisAbsence], but [UntisExcuseStatus] is not.
class UntisAbsenceReason {
  /// ID for referred to from a [UntisAbsence]
  final int id;

  /// The short name, this is usually an adjective, for example ill or delayed
  final String name;

  /// The written out reason, for example illness or delay
  final String longName;

  /// Unknown what this is, always true?
  final bool active;

  /// Parses this object from [json]
  UntisAbsenceReason.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        longName = json['longName'],
        active = json['active'];
}
