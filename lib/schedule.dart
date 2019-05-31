import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'program.dart';
import 'utils.dart';

class DaySchedule {
  String day;
  List<ScheduleEntry> entries;

  DaySchedule();
}

class ScheduleEntry {
  String id;
  String title;
  String time;
  String duration;
  String href;

  ScheduleEntry();
}

Future<List<DaySchedule>> fetchSchedule() async {
  final url = '$baseUri/grille.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var schedule = <DaySchedule>[];

    var table = document.getElementsByClassName('bmtable')[0];
    var trs = table.getElementsByTagName('tr');

    var daySchedule;
    for (dom.Element tr in trs) {
      //each class named 'titre' is a new day in the schedule
      if (tr.classes.first == 'titre') {
        daySchedule = DaySchedule();
        daySchedule.day = tr.children[0].innerHtml;
        daySchedule.entries = <ScheduleEntry>[];
        schedule.add(daySchedule);
      } else {
        var scheduleEntry = ScheduleEntry();
        var tds = tr.getElementsByTagName('td');
        String href = tds[1].children[0].attributes['href'];
        scheduleEntry.id = extractProgramId(href);
        scheduleEntry.title = stripTags(tds[1].children[0].innerHtml);
        scheduleEntry.time = stripTags(tds[0].innerHtml);
        scheduleEntry.duration = tds[2].innerHtml;
        scheduleEntry.href = href;

        daySchedule.entries.add(scheduleEntry);
      }
    }

    return schedule;
  } else {
    throw Exception('Failed to load schedule');
  }
}

class ScheduleWidget extends StatelessWidget {
  final Future<List<DaySchedule>> schedule;

  ScheduleWidget({Key key, this.schedule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DaySchedule>>(
      future: schedule,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildView(context, snapshot.data);
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Ouille ouille ouille !')),
            body: Center(child: Center(child: errorDisplay(snapshot.error))),
          );
        }

        // By default, show a loading spinner
        return Scaffold(
          appBar: AppBar(title: Text("Chargement de la programmation")),
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildView(BuildContext context, List<DaySchedule> daySchedules) {
    var rows = <ListTile>[];

    for (DaySchedule daySchedule in daySchedules) {
      rows.add(ListTile(title: Text(daySchedule.day)));

      for (ScheduleEntry scheduleEntry in daySchedule.entries) {
        rows.add(ListTile(
            title: Text(scheduleEntry.time + ' : ' + scheduleEntry.title),
            subtitle: Text(scheduleEntry.duration),
            onTap: () {
              if (scheduleEntry.id != null) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProgramPageWidget(
                            program: fetchProgram(scheduleEntry.id))));
              } else {
                onLinkTap(baseUri + scheduleEntry.href, context);
              }
            }));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("Demandez le programme ! ")),
      body: ListView(children: rows),
    );
  }
}
