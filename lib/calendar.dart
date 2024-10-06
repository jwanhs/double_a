import 'package:device_calendar/device_calendar.dart';
import 'package:double_a/models.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({super.key, required this.classSessions});

  final List<ClassSession> classSessions;

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width * 0.9,
          child: SfCalendar(
            view: CalendarView.week,
            dataSource: ClassDataSource(getAppointments(widget.classSessions)),
            timeSlotViewSettings: const TimeSlotViewSettings(
              startHour: 6,
              endHour: 22,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await exportToDeviceCalendar(context, widget.classSessions);
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_calendar_rounded),
              SizedBox(width: 8),
              Text('in den Gerätekalender exportieren'),
            ],
          ),
        ),
      ],
    );
  }
}

class ClassDataSource extends CalendarDataSource {
  ClassDataSource(List<Appointment> source) {
    appointments = source;
  }
}

List<Appointment> getAppointments(List<ClassSession> sessions) {
  List<Appointment> appointments = [];

  for (var session in sessions) {
    int weekday = _parseWeekday(session.tag);

    var times = session.zeit.split('-');
    var startTime = _parseTime(times[0]);
    var endTime = _parseTime(times[1]);

    DateTime startDate = DateTime.now();
    while (startDate.weekday != weekday) {
      startDate = startDate.add(const Duration(days: 1));
    }

    DateTime start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    DateTime end = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      endTime.hour,
      endTime.minute,
    );

    appointments.add(
      Appointment(
        startTime: start,
        endTime: end,
        subject: session.veranstatlung,
        location: session.raum,
        notes: 'Dozent: ${session.dozent}',
        recurrenceRule:
            'FREQ=WEEKLY;BYDAY=${_getRecurrenceDayString(weekday)};INTERVAL=1',
      ),
    );
  }

  return appointments;
}

DateTime _parseTime(String time) {
  var parts = time.split(':');
  var now = tz.TZDateTime.now(tz.local);
  return tz.TZDateTime(tz.local, now.year, now.month, now.day,
      int.parse(parts[0]), int.parse(parts[1]));
}

String _getRecurrenceDayString(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'MO';
    case DateTime.tuesday:
      return 'TU';
    case DateTime.wednesday:
      return 'WE';
    case DateTime.thursday:
      return 'TH';
    case DateTime.friday:
      return 'FR';
    case DateTime.saturday:
      return 'SA';
    case DateTime.sunday:
      return 'SU';
    default:
      throw ArgumentError('Invalid weekday: $weekday');
  }
}

int _parseWeekday(String tag) {
  switch (tag.toLowerCase()) {
    case 'montag':
      return DateTime.monday;
    case 'dienstag':
      return DateTime.tuesday;
    case 'mittwoch':
      return DateTime.wednesday;
    case 'donnerstag':
      return DateTime.thursday;
    case 'freitag':
      return DateTime.friday;
    case 'samstag':
      return DateTime.saturday;
    case 'sonntag':
      return DateTime.sunday;
    default:
      throw ArgumentError('Invalid day: $tag');
  }
}

tz.TZDateTime _parseTZDateTime(String day, String time) {
  int weekday = _parseWeekday(day);
  tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime dateTime = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    0,
    0,
  );

  while (dateTime.weekday != weekday) {
    dateTime = dateTime.add(const Duration(days: 1));
  }

  List<int> timeComponents = time.split(':').map(int.parse).toList();
  return dateTime
      .add(Duration(hours: timeComponents[0], minutes: timeComponents[1]));
}

Future<void> exportToDeviceCalendar(BuildContext context, List sessions) async {
  tz.initializeTimeZones();
  final DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();

  var permissionsGranted = await deviceCalendarPlugin.hasPermissions();
  if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
    permissionsGranted = await deviceCalendarPlugin.requestPermissions();
    if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calendar permissions not granted')),
      );
      return;
    }
  }

  // dialog for calendar name
  final calendarName = await showDialog<String>(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        title: const Text('Kalendername'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'neuen Kalendernamen vergeben'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: const Text('Weiter'),
          ),
        ],
      );
    },
  );

  await deviceCalendarPlugin.createCalendar(calendarName!);

  final retrievedCalendars = await deviceCalendarPlugin.retrieveCalendars();
  final selectedCalendar = retrievedCalendars.data?.firstWhere(
    (element) => element.name == calendarName,
  );

  for (var session in sessions) {
    final startTime = _parseTZDateTime(session.tag, session.zeit.split('-')[0]);
    final endTime = _parseTZDateTime(session.tag, session.zeit.split('-')[1]);

    final eventToCreate = Event(
      selectedCalendar?.id,
      title: session.veranstatlung,
      description: 'Dozent(in): ${session.dozent}',
      start: startTime,
      end: endTime,
      location: session.raum,
    );

    eventToCreate.recurrenceRule = RecurrenceRule(
      RecurrenceFrequency.Weekly,
      interval: 1,
      endDate: tz.TZDateTime.now(tz.local)
          .add(const Duration(days: 365)), // End after one year
    );

    final createEventResult =
        await deviceCalendarPlugin.createOrUpdateEvent(eventToCreate);

    if (createEventResult?.isSuccess ?? false) {
      print(
          'Event created: ${session.veranstatlung} from ${startTime.toString()} to ${endTime.toString()}');
    } else {
      print('Failed to create event: ${session.veranstatlung}');
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('All events exported to calendar')),
  );
}
