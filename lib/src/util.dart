// We don't care about missing API docs in private api.
// ignore_for_file: public_member_api_docs

/// Caution: this function is for untis DATE i.e. e.g. "2023-09-14"
DateTime? untisDateToDateTime(String? untisDate) {
  if (untisDate == null) return null;
  final List<String> split = untisDate.split('-');
  final int year = int.parse(split[0]);
  final int month = int.parse(split[1]);
  final int day = int.parse(split[2]);
  return DateTime(year, month, day);
}

/// Caution: this function is for untis TIME i.e. e.g. "T07:30"
DateTime? untisTimeToTimeOfDay(String? untisTime) {
  if (untisTime == null) return null;
  final List<String> split = untisTime.split(':');
  final int hour = int.parse(split[0].substring(1));
  final int minute = int.parse(split[1]);
  return DateTime(0, 0, 0, hour, minute);
}

/// Caution: this function is for untis DATETIME i.e. e.g. "2023-09-14T07:30Z"
DateTime? untisDateTimeToDateTime(String? dateTime) {
  if (dateTime == null) return null;
  final List<String> splitDateTime = dateTime.split('T');

  final String date = splitDateTime[0];
  final List<String> splitDate = date.split('-');
  final int year = int.parse(splitDate[0]);
  final int month = int.parse(splitDate[1]);
  final int day = int.parse(splitDate[2]);

  final String time = splitDateTime[1]
      .substring(0, splitDateTime[1].length - 1); // Get rid of the Z
  final List<String> splitTime = time.split(':');
  final int hour = int.parse(splitTime[0]);
  final int minute = int.parse(splitTime[1]);
  return DateTime(year, month, day, hour, minute);
}

String _twoDigitInt(int value) {
  if (value > 10) return '$value';
  return '0$value';
}

/// Caution: this function is for untis DATE i.e. e.g. "2023-09-14"
String? dateTimeToUntisDate(DateTime? date) {
  if (date == null) return null;
  final int year = date.year;
  final String month = _twoDigitInt(date.month);
  final String day = _twoDigitInt(date.day);
  return '$year-$month-$day';
}

/// Caution: this function is for untis TIME i.e. e.g. "T07:30"
String? dateTimeToUntisTime(DateTime? time) {
  if (time == null) return null;
  final String hour = _twoDigitInt(time.hour);
  final String minute = _twoDigitInt(time.minute);
  return 'T$hour:$minute';
}

/// Caution: this function is for untis DATETIME i.e. e.g. "2023-09-14T07:30Z"
String? dateTimeToUntisDateTime(DateTime? dateTime) {
  if (dateTime == null) return null;
  final String date = dateTimeToUntisDate(dateTime)!;
  final String time = dateTimeToUntisTime(dateTime)!;
  return '$date${time}Z';
}

/// Converts [untisDay](e.g "MON") to a weekday int
///
/// This method uses DateTime.monday to DateTime.sunday, so 1 - 7
int untisWeekDayToDateTimeWeekDay(String untisDay) {
  switch (untisDay) {
    case 'MON':
      return DateTime.monday;
    case 'TUE':
      return DateTime.tuesday;
    case 'WED':
      return DateTime.wednesday;
    case 'THU':
      return DateTime.thursday;
    case 'FRI':
      return DateTime.friday;
    case 'SAT':
      return DateTime.saturday;
    case 'SUN':
      return DateTime.sunday;
  }
  return -1;
}

/// Iterate over every value of a json object list and apply fromJson function
///
/// Parses a [jsonList] of objects to a list of [T]
List<T>? iterateFromJson<T>(T Function(Map<String, dynamic>) fromJsonFunction,
    List<dynamic>? jsonList) {
  // Maybe this is not needed?, only in case of API change or transmission error
  if (jsonList == null) return null;
  final List<T> objects = <T>[
    for (final Map<String, dynamic> entry in jsonList) fromJsonFunction(entry)
  ];
  return objects.isEmpty ? null : objects;
}

// Thanks to creativecreatorormaybenot & Md. Yeasin Sheikh
// https://stackoverflow.com/questions/50081213/how-do-i-use-hexadecimal-color-strings-in-flutter
/// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
int colorValueFromHex(String hexString) {
  final StringBuffer buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return int.parse(buffer.toString(), radix: 16);
}

Future<T> execAsyncFuncIfNull<T>(T? variable, dynamic Function() func) async {
  if (variable == null) await func();
  return variable as T;
}

extension IterableGroupable<T> on Iterable<T> {
  Map<K, List<T>> groupListsBy<K>(K Function(T element) keyOf) {
    final Map<K, List<T>> result = <K, List<T>>{};
    for (final T element in this) {
      (result[keyOf(element)] ??= <T>[]).add(element);
    }
    return result;
  }

  List<List<T>> groupListsByInt(int Function(T element) keyOf) {
    final Map<int, List<T>> map = groupListsBy(keyOf);
    // the returned int will be used as index for the list
    map.entries.toList().sort(
        (MapEntry<int, List<T>> a, MapEntry<int, List<T>> b) =>
            a.key.compareTo(b.key));

    return map.values.toList();
  }
}

extension JustTime on DateTime {
  DateTime copyWithHHM() => DateTime(0, 0, 0, hour, minute);
}
