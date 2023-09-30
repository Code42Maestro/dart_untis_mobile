import 'package:flutter/material.dart';
import 'package:dart_untis_mobile/untis_mobile.dart';

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
      title: 'Untis Mobile demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
    fetchUntis().whenComplete(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<List<UntisPeriod?>> periods = [];
    if (tt != null && grid != null) periods = tt!.groupedPeriods(grid!);
    List<List<PeriodWidget>> pWidgets = periods
        .map((plist) => plist.map((p) => PeriodWidget(period: p)).toList())
        .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: GridView.builder(
        itemCount: tt != null ? tt!.periods.length : 0,
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid?.days.length ?? 1),
        itemBuilder: (BuildContext context, int index) {
          // Calculate row and column values based on the index
          int row = index ~/ grid!.days.length; // Floor division operator
          int column = index % grid!.days.length;
          print("row: $row, column: $column");
          return pWidgets[column][row];
        },
      ),
    );
  }

  Future<void> fetchUntis() async {
    // These need to be defined from cli (--dart-define)
    // https://dartcode.org/docs/using-dart-define-in-flutter/
    const server = String.fromEnvironment('UNTIS_SERVER');
    if (server.isEmpty) {
      throw AssertionError('UNTIS_SERVER is not set');
    }
    const school = String.fromEnvironment('UNTIS_SCHOOL');
    if (school.isEmpty) {
      throw AssertionError('UNTIS_SCHOOL is not set');
    }
    const username = String.fromEnvironment('UNTIS_USER');
    if (username.isEmpty) {
      throw AssertionError('UNTIS_USER is not set');
    }
    const password = String.fromEnvironment('UNTIS_PASS');
    if (password.isEmpty) {
      throw AssertionError('UNTIS_PASS is not set');
    }
    final UntisSession s =
        await UntisSession.init(server, school, username, password);
    DateTime date = DateTime.now().subtract(Duration(days: 14));
    while (date.weekday != 1) {
      date = date.subtract(Duration(days: 1));
    }
    grid = await s.timeGrid;
    tt = await s.getTimetable(
      startDate: date,
      endDate: date.add(Duration(days: 1)),
    );
  }
}

class PeriodWidget extends StatelessWidget {
  final UntisPeriod? period;

  const PeriodWidget({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    if (period == null) return Center(child: Text("NIX"));
    return Center(
        child: Column(children: [
      Text(period!.subjects.isNotEmpty
          ? period!.subjects.first.longName
          : period!.text.lesson),
      Text(period!.startDateTime.day.toString())
    ]));
  }
}
