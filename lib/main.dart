import 'package:dio/dio.dart';
import 'package:double_a/calendar.dart';
import 'package:double_a/dio_singleton.dart';
import 'package:double_a/filter_dropdown.dart';
import 'package:double_a/models.dart';
import 'package:double_a/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Dio dio = DioSingleton.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await createSecureHttpClient();

  tz.initializeTimeZones();
  runApp(const MainApp());
}

Future<void> createSecureHttpClient() async {
  try {
    SecurityContext context = SecurityContext.defaultContext;

    String certchain = await rootBundle.loadString('assets/ca/fullchain.pem');
    context.setTrustedCertificatesBytes(utf8.encode(certchain));
  } catch (e) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(e.toString()),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<Response<dynamic>?> fetchTimetable() async {
    try {
      Response timetableResponse = await dio.get(
        'https://wwwccb.hochschule-bochum.de/campusInfo/newslist/displayTimetable.php',
      );

      String responseString = latin1.decode(timetableResponse.data);

      if (responseString.contains('Nicht angemeldet')) {
        _showErrorSnackBar(
            Exception(
              'Bitte Anmeldedaten prüfen und erneut versuchen.',
            ),
            'Abfrage fehlgeschlagen: ');
        return null;
      }

      return Response(
        data: responseString,
        requestOptions: timetableResponse.requestOptions,
        statusCode: timetableResponse.statusCode,
        statusMessage: timetableResponse.statusMessage,
      );
    } catch (e) {
      _showErrorSnackBar(
          e as Exception, 'Fehler beim Abrufen des Stundenplans: ');
      return null;
    }
  }

  void sanitizeDropdownOptions(BuildContext context, String htmlString) {
    try {
      dom.Document document = html_parser.parse(htmlString);

      if (mounted) {
        lecturerController.clear();
        roomController.clear();
        dayController.clear();
        timeController.clear();
        semesterController.clear();
      }

      lecturers.clear();
      rooms.clear();
      days.clear();
      times.clear();
      semesters.clear();

      for (var lecturerOption
          in document.querySelectorAll('select[name="lecturer_nr"] option')) {
        if (lecturerOption.text.trim().endsWith(",")) {
          // <option value="245">Abstoss, </option>
          // add as {245: Abstoss}
          lecturers[lecturerOption.attributes['value']] =
              Lecturer(lecturerOption.text.trim().lastChars(1));
        } else {
          lecturers[lecturerOption.attributes['value']] =
              Lecturer(lecturerOption.text.trim());
        }
      }

      for (var roomOption
          in document.querySelectorAll('select[name="room_nr"] option')) {
        rooms[roomOption.attributes['value']] = Room(roomOption.text.trim());
      }

      for (var dayOption
          in document.querySelectorAll('select[name="day_nr"] option')) {
        days[dayOption.attributes['value']] = Day(dayOption.text.trim());
      }

      for (var timeOption
          in document.querySelectorAll('select[name="time_nr"] option')) {
        times[timeOption.attributes['value']] = Time(timeOption.text.trim());
      }

      for (var semesterOption in document
          .querySelectorAll('select[name="semestergroup_nr"] option')) {
        semesters[semesterOption.attributes['value']] =
            Semester(semesterOption.text.trim());
      }

      lecturers[lecturers.keys.first] = const Lecturer('Alle Dozenten');
      rooms[rooms.keys.first] = const Room('Alle Räume');
      rooms.remove(rooms.keys.elementAt(1));
      days[days.keys.first] = const Day('Alle Tage');
      times[times.keys.first] = const Time('Alle Zeiten');
      semesters[semesters.keys.first] = const Semester('Alle Semester');

      lecturerController.value = lecturers.values.first;
      roomController.value = rooms.values.first;
      dayController.value = days.values.first;
      // lastSelectedDays = days.values.toList();
      timeController.value = times.values.first;
      // lastSelectedTimes = times.values.toList();

      setState(() {});
    } catch (e) {
      _showErrorSnackBar(e as Exception, 'Fehler bei der Verarbeitung: ');
    }
  }

  Future<bool> login(
      {required String username, required String password}) async {
    try {
      await dio.get('https://wwwccb.hochschule-bochum.de/campusInfo/index.php');

      FormData formData = FormData.fromMap({
        'username': username,
        'loginPassword': password,
        'show': 'Anmelden',
      });

      await dio.post(
        'https://wwwccb.hochschule-bochum.de/campusInfo/index.php',
        data: formData,
      );
      return true;
    } catch (e) {
      _showErrorSnackBar(
        e is Exception ? e : Exception(e.toString()),
      );
      return false;
    }
  }

  void _showErrorSnackBar(
    Exception e, [
    String friendlyMessage = '',
  ]) {
    if (!mounted) return;

    final String message = (e is! DioException)
        ? '$friendlyMessage${e.toString().replaceFirst('Exception: ', '')}'
        : switch (e.type) {
            DioExceptionType.connectionTimeout =>
              'Zeitüberschreitung bei der Verbindung...',
            DioExceptionType.sendTimeout => 'Zeitüberschreitung beim Senden...',
            DioExceptionType.receiveTimeout =>
              'Zeitüberschreitung beim Empfangen...',
            DioExceptionType.cancel => 'Anfrage abgebrochen.',
            DioExceptionType.badResponse =>
              'Fehlerhafte Antwort empfangen: ${e.response?.statusCode}',
            DioExceptionType.badCertificate =>
              'Bitte Netzwerkverbindung überprüfen.',
            DioExceptionType.connectionError => 'Verbindungsfehler...',
            DioExceptionType.unknown when e.error is SocketException =>
              'Keine Internetverbindung!',
            DioExceptionType.unknown when e.error is HttpException =>
              'Kommunikationsfehler: ${e.error}',
            DioExceptionType.unknown when e.error is FormatException =>
              'Formatfehler: ${e.error}',
            _ => 'Unbekannter Fehler: ${e.message} (${e.type})',
          };

    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  Future<void> searchTable() async {
    try {
      FormData formData = FormData.fromMap({
        'lecturer_nr': lecturers.keys.where((element) {
          return lecturers[element] == lecturerController.value;
        }).first,
        'room_nr': rooms.keys.where((element) {
          return rooms[element] == roomController.value;
        }).first,
        'day_nr': days.keys.where((element) {
          return days[element] == dayController.value;
        }).first,
        'time_nr': times.keys.where((element) {
          return times[element] == timeController.value;
        }).first,
        'semestergroup_nr': semesters.keys.where((element) {
          return semesters[element] == semesterController.value;
        }).first,
        'lm': 'l',
        'print': '0',
        'sendForm': 'Anzeigen',
      });

      Response loginResponse = await dio.post(
        'https://wwwccb.hochschule-bochum.de/campusInfo/newslist/displayTimetable.php',
        data: formData,
      );
      parseTable(latin1.decode(loginResponse.data), filters: {
        'dozent/in': lecturerController.value!.name,
        'raum': roomController.value!.name,
        'tag': dayController.value!.name,
        'zeit': timeController.value!.name,
        'semester': semesterController.value!.name,
      });
    } catch (e) {
      _showErrorSnackBar(
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  void parseTable(String htmlString, {required Map<String, String?> filters}) {
    tableData.clear();

    try {
      dom.Document document = html_parser.parse(htmlString);

      var rows =
          document.querySelectorAll('table')[1].querySelectorAll('tr').skip(1);

      for (var row in rows) {
        for (var cell in row.querySelectorAll('td').take(5)) {
          if (cell.text.isNotEmpty) {
            tableData.add(cell.text);
          }
        }
      }

      classSessions = parseClasses(tableData);

      setState(() {});
    } catch (e) {
      _showErrorSnackBar(
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  void initState() {
    lecturerController = SingleSelectController(null);
    roomController = SingleSelectController(null);
    dayController = SingleSelectController(null);
    timeController = SingleSelectController(null);
    semesterController = SingleSelectController(null);
    calendarController = CalendarController();
    super.initState();
  }

  @override
  void dispose() {
    lecturerController.dispose();
    roomController.dispose();
    dayController.dispose();
    timeController.dispose();
    semesterController.dispose();
    calendarController.dispose();
    pageIndicatorController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  List<BoxShadow> elevation = [
    BoxShadow(
      color: Color.fromARGB(
        90,
        0,
        0,
        0,
      ),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  Map<dynamic, Lecturer> lecturers = {};
  Map<dynamic, Room> rooms = {};
  Map<dynamic, Day> days = {};
  Map<dynamic, Time> times = {};
  Map<dynamic, Semester> semesters = {};

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  late SingleSelectController<Lecturer> lecturerController;
  late SingleSelectController<Room> roomController;
  late SingleSelectController<Day> dayController;
  late SingleSelectController<Time> timeController;
  late SingleSelectController<Semester> semesterController;

  List<Time> lastSelectedTimes = [];
  List<Day> lastSelectedDays = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: lightThemeData,
      darkTheme: lightThemeData,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        SfGlobalLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('de'),
      ],
      locale: const Locale('de'),
      home: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              PageView(
                controller: pageIndicatorController,
                children: [
                  SingleChildScrollView(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Column(
                                children: [
                                  TextField(
                                    controller: usernameController,
                                    decoration: getStandardInputDecoration(
                                      context,
                                      labelText: 'Benutzername',
                                      hintText: 'Benutzername eingeben',
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  TextField(
                                    obscureText: true,
                                    controller: passwordController,
                                    decoration: getStandardInputDecoration(
                                      context,
                                      labelText: 'Kennwort',
                                      hintText: 'Kennwort eingeben',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2.0),
                              ElevatedButton(
                                onPressed: () async {
                                  bool loginSuccess = await login(
                                      username: usernameController.text,
                                      password: passwordController.text);

                                  final timetableRequest =
                                      await fetchTimetable();
                                  if (timetableRequest != null &&
                                      context.mounted) {
                                    sanitizeDropdownOptions(context,
                                        timetableRequest.data.toString());

                                    FocusScope.of(context).unfocus();
                                    ScaffoldMessenger.of(
                                            _scaffoldKey.currentContext!)
                                        .showSnackBar(
                                      const SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Sie können Ihre Suche jetzt verfeinern!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Anmelden'),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Theme(
                                  data: ThemeData(),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 6),
                                      FilterDropdown<Lecturer>(
                                        useSearch: true,
                                        enabled: lecturers.isNotEmpty,
                                        controller: lecturerController,
                                        prefixIcon: Icon(Icons.person_search),
                                        hintText: 'Dozent/in',
                                        items: lecturers.values.toList(),
                                        onChanged: (value) {},
                                      ),
                                      const SizedBox(height: 8),
                                      FilterDropdown<Room>(
                                        useSearch: true,
                                        enabled: rooms.isNotEmpty,
                                        controller: roomController,
                                        prefixIcon: Icon(Icons.class_outlined),
                                        hintText: 'Raum',
                                        items: rooms.values.toList(),
                                        onChanged: (value) {},
                                      ),
                                      const SizedBox(height: 8),
                                      FilterDropdown<Day>(
                                        enabled: days.isNotEmpty,
                                        controller: dayController,
                                        prefixIcon: Icon(Icons.sunny_snowing),
                                        hintText: 'Tag',
                                        items: days.values.toList(),
                                        onChanged: (value) {},
                                      ),
                                      const SizedBox(height: 8),
                                      FilterDropdown<Time>(
                                        enabled: times.isNotEmpty,
                                        controller: timeController,
                                        prefixIcon: Icon(Icons.av_timer),
                                        hintText: 'Zeit',
                                        items: times.values.toList(),
                                        onChanged: (value) {},
                                      ),
                                      const SizedBox(height: 8),
                                      FilterDropdown<Semester>(
                                        enabled: semesters.isNotEmpty,
                                        controller: semesterController,
                                        prefixIcon: Icon(Icons.calendar_month),
                                        hintText: 'Bitte Semester wählen',
                                        items: semesters.values.toList(),
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              ElevatedButton(
                                onPressed: semesterController.value == null
                                    ? null
                                    : () async {
                                        if (semesterController.value!.name == 'Alle Semester' &&
                                            lecturerController.value!.name ==
                                                'Alle Dozenten' &&
                                            roomController.value!.name ==
                                                'Alle Räume') {
                                          _showErrorSnackBar(
                                            Exception(
                                                'Bitte wählen Sie mindestens einen Dozenten oder Raum aus, um die Suche einzugrenzen.'),
                                          );
                                          return;
                                        }
                                        await searchTable();

                                        if (classSessions.isNotEmpty) {
                                          calendarController.displayDate =
                                              getAppointments(classSessions)
                                                  .firstWhere(
                                                    (session) =>
                                                        session.startTime.day ==
                                                        DateTime.now().day,
                                                    orElse: () =>
                                                        getAppointments(
                                                      classSessions,
                                                    ).first,
                                                  )
                                                  .startTime;
                                          pageIndicatorController.animateToPage(
                                            1,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeIn,
                                          );
                                        } else {
                                          _showErrorSnackBar(Exception(
                                            'Derzeit keine gesuchten Einträge vorhanden',
                                          ));
                                        }
                                      },
                                child: const Text('Stundenplan ansehen'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomCalendar(
                          classSessions: classSessions,
                          calendarController: calendarController,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                left: 0,
                bottom: 20,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SmoothPageIndicator(
                    controller: pageIndicatorController,
                    count: 2,
                    effect: const JumpingDotEffect(
                      dotColor: Color(0xFFFFBE93),
                      activeDotColor: Color(0xFFEF6C00),
                    ),
                    onDotClicked: (index) {
                      pageIndicatorController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  late CalendarController calendarController;

  List<Class> parseClasses(List<String> data) {
    List<Class> sessions = [];

    List<bool> filtering = [
      lecturerController.value!.name == 'Alle Dozenten',
      true, // veranstaltung
      dayController.value!.name == 'Alle Tage',
      timeController.value!.name == 'Alle Zeiten',
      roomController.value!.name == 'Alle Räume',
      semesterController.value!.name == 'Alle Semester',
    ];

    int index = 0;
    while (index < data.length) {
      String dozent =
          filtering[0] ? data[index++] : lecturerController.value!.name;

      String veranstaltung = data[index++];
      String tag = filtering[2] ? data[index++] : dayController.value!.name;
      String zeit = filtering[3] ? data[index++] : timeController.value!.name;
      String raum = filtering[4] ? data[index++] : roomController.value!.name;
      String semester =
          filtering[5] ? data[index++] : roomController.value!.name;

      sessions.add(Class(
        dozent: dozent,
        veranstatlung: veranstaltung,
        tag: tag,
        zeit: zeit,
        raum: raum,
      ));
    }
    return sessions;
  }

  final pageIndicatorController =
      PageController(viewportFraction: 1, initialPage: 0);
}

List<String> tableData = [];
List<Class> classSessions = [];

extension E on String {
  String lastChars(int n) => substring(0, length - n);
}
