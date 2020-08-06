class DaySchedule {
  String day;
  List<ScheduleEntry> entries;

  DaySchedule();
}

class ScheduleEntry {
  int id;
  String title;
  String time;
  String duration;
  String href;

  ScheduleEntry();
}
