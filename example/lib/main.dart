import 'dart:async';

import 'package:dart_untis_mobile/dart_untis_mobile.dart';
import 'package:flutter/material.dart';

// We don't care about missing API docs in the example app.
// ignore_for_file: public_member_api_docs

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Untis Mobile Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Untis Mobile Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  UntisTimetable? tt;
  UntisTimeGrid? grid;

  @override
  void initState() {
    super.initState();
    unawaited(fetchUntis().whenComplete(() {
      setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    List<List<UntisPeriod?>> periods = <List<UntisPeriod?>>[];
    if (tt != null && grid != null) periods = tt!.groupedPeriods(grid!);
    final List<List<PeriodWidget>> pWidgets = periods
        .map((List<UntisPeriod?> plist) =>
            plist.map((UntisPeriod? p) => PeriodWidget(period: p)).toList())
        .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: GridView.builder(
        // itemCount needs to include all the periods, also null ones
        itemCount: tt != null
            ? periods
                .map((plist) => plist.length)
                .reduce((value, element) => value + element)
            : 0,
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid?.days.length ?? 1),
        itemBuilder: (BuildContext context, int index) {
          // Calculate row and column values based on the index
          final int row = index ~/ grid!.days.length; // Floor division operator
          final int column = index % grid!.days.length;

          return Container(
              // Make Grid visible (each cell draws border)
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black54,
                  width: 0.3,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(1),
                child: pWidgets[column][row],
              ));
        },
      ),
    );
  }

  Future<void> fetchUntis() async {
    // These need to be defined from cli (--dart-define)
    // https://dartcode.org/docs/using-dart-define-in-flutter/
    const String server = String.fromEnvironment('UNTIS_SERVER');
    if (server.isEmpty) {
      throw AssertionError(
          'Please specify UNTIS_SERVER with --dart-define UNTIS_SERVER=');
    }
    const String school = String.fromEnvironment('UNTIS_SCHOOL');
    if (school.isEmpty) {
      throw AssertionError(
          'Please specify UNTIS_SCHOOL with --dart-define UNTIS_SCHOOL=');
    }
    const String username = String.fromEnvironment('UNTIS_USER');
    if (username.isEmpty) {
      throw AssertionError(
          'Please specify UNTIS_USER with --dart-define UNTIS_USER=');
    }
    const String password = String.fromEnvironment('UNTIS_PASS');
    if (password.isEmpty) {
      throw AssertionError(
          'Please specify UNTIS_PASS with --dart-define UNTIS_PASS=');
    }
    final UntisSession s =
        await UntisSession.init(server, school, username, password);
    DateTime date = DateTime.now().subtract(const Duration(days: 14));
    while (date.weekday != 1) {
      date = date.subtract(const Duration(days: 1));
    }
    grid = await s.timeGrid;
    tt = await s.getTimetable(
      startDate: date,
      endDate: date.add(const Duration(days: 1)),
    );
  }
}

class PeriodWidget extends StatelessWidget {
  final UntisPeriod? period;

  const PeriodWidget({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    if (period == null) return const Center(child: Text('X'));
    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12, width: 2),
          borderRadius: BorderRadius.circular(10),
          color:
              Color(period!.subject!.backColorValue ?? period!.backColorValue),
        ),
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(
              period!.subjects.isNotEmpty
                  ? period!.subject!.longName
                  : period!.text.lesson,
              textAlign: TextAlign.center),
          Text(
              period!.teachers.isNotEmpty
                  ? period!.teacher!.fullName
                  : "No teacher",
              textAlign: TextAlign.center),
          Text(period!.rooms.isNotEmpty ? period!.room!.name : "Not in School",
              textAlign: TextAlign.center)
        ])));
  }
}
