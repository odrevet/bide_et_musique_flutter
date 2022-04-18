import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/schedule.dart';
import '../session.dart';
import '../utils.dart';

Future<List<DaySchedule?>> fetchSchedule() async {
  const url = '$baseUri/grille.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var schedule = <DaySchedule?>[];

    var table = document.getElementsByClassName('bmtable')[0];
    var trs = table.getElementsByTagName('tr');

    late DaySchedule daySchedule;
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
        String href = tds[1].children[0].attributes['href']!;
        scheduleEntry.id = getIdFromUrl(href);
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
