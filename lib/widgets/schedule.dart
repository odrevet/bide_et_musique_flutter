import 'dart:async';

import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../utils.dart';
import 'error_display.dart';

class Schedule extends StatelessWidget {
  final Future<List<DaySchedule?>>? schedule;

  const Schedule({super.key, this.schedule});

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
    final theme = Theme.of(context);
    var rows = <Widget>[];

    for (DaySchedule? daySchedule in daySchedules) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            daySchedule!.day,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );

      for (ScheduleEntry scheduleEntry in daySchedule.entries) {
        rows.add(
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: ListTile(
              title: Text(
                '${scheduleEntry.time}  ${scheduleEntry.title}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(scheduleEntry.duration),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => onLinkTap(baseUri + scheduleEntry.href, context),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Demandez le programme !")),
      body: ListView(children: rows),
    );
  }
}
