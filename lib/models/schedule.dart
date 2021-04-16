class DaySchedule {
  late String day;
  late List<ScheduleEntry> entries;

  DaySchedule();
}

class ScheduleEntry {
  int? id;
  late String title;
  late String time;
  late String duration;
  late String href;

  ScheduleEntry();
}
