import 'package:device_calendar/device_calendar.dart';
import 'package:double_a/models.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CustomCalendar extends StatefulWidget {
  const CustomCalendar(
      {super.key,
      required this.classSessions,
      required this.calendarController});

  final List<Class> classSessions;
  final CalendarController calendarController;

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  bool exportLoading = false;

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 5),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width * 0.9,
          child: SfCalendar(
            controller: widget.calendarController,
            headerStyle: const CalendarHeaderStyle(
              textAlign: TextAlign.right,
              backgroundColor: Color(0xFFFBEFE3),
            ),
            view: CalendarView.day,
            dataSource: ClassDataSource(getAppointments(widget.classSessions)),
            timeSlotViewSettings: const TimeSlotViewSettings(
              startHour: 6,
              endHour: 22,
            ),
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: exportLoading ? null : 0,
          minHeight: 3,
        ),
        const SizedBox(height: 2),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit_calendar_rounded),
          onPressed: () async {
            await exportToDeviceCalendar(context, widget.classSessions);
          },
          label: const Text('in den Gerätekalender exportieren'),
        ),
      ],
    );
  }

  Future<void> exportToDeviceCalendar(
      BuildContext context, List<Class> sessions) async {
    tz.initializeTimeZones();
    final DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();

    var permissionsGranted = await deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kalendarberechtigungen nicht erteilt'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    if (context.mounted) {
      final calendarName = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Kalendername'),
            content: TextField(
              onSubmitted: (value) {
                Navigator.of(context).pop(controller.text);
                setState(() {
                  exportLoading = true;
                });
              },
              controller: controller,
              decoration: const InputDecoration(
                  hintText: 'neuen Kalendernamen vergeben'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                  setState(() {
                    exportLoading = true;
                  });
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
        final startTime =
            _parseLocalDateTime(session.tag, session.zeit.split('-')[0]);
        final endTime =
            _parseLocalDateTime(session.tag, session.zeit.split('-')[1]);

        final tz.TZDateTime tzStartTime =
            tz.TZDateTime.from(startTime, tz.local);
        final tz.TZDateTime tzEndTime = tz.TZDateTime.from(endTime, tz.local);

        final eventToCreate = Event(
          selectedCalendar?.id,
          title: session.veranstatlung,
          description: 'Dozent(in): ${session.dozent}',
          start: tzStartTime,
          end: tzEndTime,
          location: session.raum,
        );

        eventToCreate.recurrenceRule = RecurrenceRule(
          frequency: Frequency.weekly,
          interval: 1,
          until: tz.TZDateTime.now(tz.local).add(const Duration(days: 119)),
        );

        await deviceCalendarPlugin.createOrUpdateEvent(eventToCreate);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
                '${sessions.length} Veranstaltungen in den Gerätekalender exportiert'),
          ),
        );
        setState(() {
          exportLoading = false;
        });
      }
    }
  }
}

class ClassDataSource extends CalendarDataSource {
  ClassDataSource(List<Appointment> source) {
    appointments = source;
  }
}

List<Appointment> getAppointments(List<Class> sessions) {
  List<Appointment> appointments = [];

  for (var session in sessions) {
    int weekday = _parseWeekday(session.tag);
    String subject = session.veranstatlung;
    if (session.semester != null) {
      subject = "$subject (${session.semester})";
    }

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
        notes: 'Dozent(in): ${session.dozent}',
        recurrenceRule:
            'FREQ=WEEKLY;BYDAY=${_getRecurrenceDayString(weekday)};INTERVAL=1',
      ),
    );
  }

  return appointments;
}

DateTime _parseTime(String time) {
  var parts = time.split(':');
  var now = DateTime.now();
  return DateTime(
      now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
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

DateTime _parseLocalDateTime(String day, String time) {
  int weekday = _parseWeekday(day);
  DateTime now = DateTime.now();

  DateTime dateTime = DateTime(now.year, now.month, now.day);
  while (dateTime.weekday != weekday) {
    dateTime = dateTime.add(const Duration(days: 1));
  }

  List<int> timeComponents = time.split(':').map(int.parse).toList();
  return DateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    timeComponents[0],
    timeComponents[1],
  );
}
