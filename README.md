[![Pub Package](https://img.shields.io/pub/v/dart_untis_mobile.svg)](https://pub.dev/packages/dart_untis_mobile)
[![package publisher](https://img.shields.io/pub/publisher/dart_untis_mobile.svg)](https://pub.dev/packages/dart_untis_mobile/publisher)

# dart_untis_mobile

**dart_untis_mobile** is a pure Dart library for the untis mobile API, which provides read-only
access to the
school timetable system used in Germany.

## Features

- Login to the untis mobile API using provided credentials
- Retrieve the timetable for a specific date and user/class
- Fetch information about subjects, teachers, rooms, and students
- Access homework and get detailed information about homework
- Retrieve school year information
- Get school holidays
- Fetch absences, that may not be excused

## Getting Started

To use this library, add `dart_untis_mobile` as a dependency in your `pubspec.yaml` file.

## Usage

Import the library and initialize an instance of the `UntisSession` class with your credentials:

```dart
import 'package:dart_untis_mobile/dart_untis_mobile.dart';

void main() async {
  final session = await UntisSession.init(
    server: 'your_server',
    school: 'your_school',
    username: 'your_username',
    password: 'your_password',
  );

  // Use session methods to access the API and perform actions
}
```

## Examples

### Retrieve Homework directly

```dart

final List<UntisHomework> homework = await
session.getHomework
();

// Use the homework data
for
(
final UntisHomework hw in homework) {
print('Until: ${hw.endDate}, Task: ${hw.text}');
}
```

### Retrieve Subjects, that are relevant

```dart
// Gets the timetable from the current date
final List<UntisSubject> subjects = await
session.getCurrentSubjects
();

// Inform about the current subjects
for
(
final UntisSubject subject in subjects) {
print('Subject: ${subject.longName}, short: ${subject.name}');
}
```

### Retrieve Timetable

```dart
// Gets the timetable from the current date
final UntisTimetable timetable = await
session.getTimetable
(
startDate: DateTime.now(),
endDate: DateTime.now().add(const Duration(days: 7)));

// Use the timetable data 
for (final UntisPeriod period in timetable.periods) {
print('Subject: ${period.subject?.longName}, Room: ${period.room?.name}, Teacher: ${period.teacher?.lastName}');
}
```

### Get lessons of this month and filter subject

```dart
// Gets the timetable of this month
final UntisTimetable timetable = await
session.getTimetable
(
startDate: DateTime.now(),
endDate: DateTime.now().add(const Duration(days: 7 * 4)));

// Filter out the subject
final List<UntisPeriod> mathPeriods = timetable.periods
    .where((UntisPeriod p) => p.subject!.name == 'Ma')
    .toList();
final UntisTeacher mathTeacher = mathPeriods.first.teacher!;
print('You will have math ${mathPeriods.length} times, with ${mathTeacher.fullName}');
```

### Group Timetable by time grid(days)

```dart

final UntisTimeGrid timegrid = await
session.timeGrid;

// Use Timetable and TimeGrid to group by day
final List<List<UntisPeriod?>> days = tt.groupedPeriods(grid);

// Use this data
for (
final UntisPeriod? period in days[0]) {
if (period == null) {
print("Nothing here");
continue;
}
final int hour = period.startDateTime.hour;
final int minute = period.startDateTime.minute;
print('Time: $hour:$minute Subject: ${period.subject}');
}

```

## Contributions

There are features, that are not implemented. So please file a issue if you need something or found
a bug.

This library is open for contributions :)

## License

This library is licensed under the [MIT License](LICENSE).