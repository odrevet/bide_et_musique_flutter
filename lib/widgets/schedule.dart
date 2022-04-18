import 'dart:async';

import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../utils.dart';
import 'error_display.dart';

class Schedule extends StatelessWidget {
  final Future<List<DaySchedule?>>? schedule;

  const Schedule({Key? key, this.schedule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DaySchedule?>>(
      future: schedule,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildView(context, snapshot.data!);
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ouille ouille ouille !')),
            body: Center(child: ErrorDisplay(snapshot.error)),
          );
        }

        // By default, show a loading spinner
        return Scaffold(
          appBar: AppBar(title: const Text("Chargement de la programmation")),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildView(BuildContext context, List<DaySchedule?> daySchedules) {
    var rows = <ListTile>[];

    for (DaySchedule? daySchedule in daySchedules) {
      rows.add(ListTile(title: Text(daySchedule!.day)));

      for (ScheduleEntry scheduleEntry in daySchedule.entries) {
        rows.add(ListTile(
            title: Text(scheduleEntry.time + ' : ' + scheduleEntry.title),
            subtitle: Text(scheduleEntry.duration),
            onTap: () => onLinkTap(baseUri + scheduleEntry.href, context)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Demandez le programme ! ")),
      body: ListView(children: rows),
    );
  }
}
