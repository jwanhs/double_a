import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:dio/dio.dart';
import 'package:double_a/calendar.dart';
import 'package:double_a/dio_singleton.dart';
import 'package:double_a/models.dart';
import 'package:double_a/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;

Dio dio = DioSingleton.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  tz.initializeTimeZones();
  runApp(const MainApp());
}

Future<Response<dynamic>?> fetchTimetable() async {
  try {
    Response timetableResponse = await dio.get(
      'https://wwwccb.hochschule-bochum.de/campusInfo/newslist/displayTimetable.php',
    );

    String responseString = latin1.decode(timetableResponse.data);

    return Response(
      data: responseString,
      requestOptions: timetableResponse.requestOptions,
    );
  } catch (e) {
    log('Error fetching timetable: $e');
  }
  return null;
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<void> login(
      {required String username, required String password}) async {
    try {
      await dio.get('https://wwwccb.hochschule-bochum.de/campusInfo/index.php');

      FormData formData = FormData.fromMap({
        'username': username,
        'loginPassword': password,
        'show': 'Anmelden',
      });

      Response loginResponse = await dio.post(
        'https://wwwccb.hochschule-bochum.de/campusInfo/index.php',
        data: formData,
      );

      if (loginResponse.statusCode == 200) {
        log(loginResponse.data.toString());
      } else {
        log('Request failed: ${loginResponse.statusCode}');
      }
    } catch (e) {
      log('Error on login: $e');
    }
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

      if (loginResponse.statusCode == 200) {
        parseTable(latin1.decode(loginResponse.data));
      } else {
        log('Request failed: ${loginResponse.statusCode}');
      }
    } catch (e) {
      log('Error on login: $e');
    }
  }

  void parseTable(String htmlString) {
    if (htmlString.isEmpty) {
      log('Result body empty');
    }

    tableData.clear();

    try {
      dom.Document document = html_parser.parse(htmlString);

      for (var table in document.querySelectorAll('table')) {
        var rows = table.querySelectorAll('tr').skip(1);

        for (var row in rows) {
          for (var cell in row.querySelectorAll('td')) {
            if (cell.text.isNotEmpty) {
              tableData.add(cell.text);
            }
          }
        }
      }
      classSessions = parseToClassSessions(tableData);
      setState(() {});
    } catch (e) {
      log('Error parsing table: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    lecturerController = SingleSelectController(lecturers.values.first);
    roomController = SingleSelectController(rooms.values.first);
    dayController = SingleSelectController(days.values.first);
    timeController = SingleSelectController(times.values.first);
    semesterController = SingleSelectController(semesters.values.first);
  }

  Map<dynamic, Lecturer> lecturers = {"%": const Lecturer("Alle Dozenten")};
  Map<dynamic, Room> rooms = {"%": const Room("Alle Räume")};
  Map<dynamic, Day> days = {"%": const Day("Alle Tage")};
  Map<dynamic, Time> times = {"%": const Time("Alle Zeiten")};
  Map<dynamic, Semester> semesters = {"%": const Semester("Alle Semester")};

  void sanitizeDropdownOptions(BuildContext context, String htmlString) {
    if (htmlString.isEmpty) {
      log('Result body empty');
    }

    try {
      dom.Document document = html_parser.parse(htmlString);

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

      lecturers[lecturers.keys.first] = const Lecturer("Alle Dozenten");
      lecturerController.value = lecturers.values.first;
      rooms[rooms.keys.first] = const Room("Alle Räume");
      rooms.remove(rooms.keys.elementAt(1));
      roomController.value = rooms.values.first;
      days[days.keys.first] = const Day("Alle Tage");
      dayController.value = days.values.first;
      // lastSelectedDays = days.values.toList();
      times[times.keys.first] = const Time("Alle Zeiten");
      timeController.value = times.values.first;
      // lastSelectedTimes = times.values.toList();
      semesters[semesters.keys.first] = const Semester("Alle Semester");
      semesterController.value = semesters.values.first;

      setState(() {});
    } catch (e) {
      log('Error parsing dropdown options: $e');
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            "Fehler bei der Abfrage. Bitte Anmeldedaten prüfen und erneut versuchen.",
          ),
        ),
      );
    }
  }

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  late SingleSelectController<Lecturer> lecturerController =
      SingleSelectController(null);
  late SingleSelectController<Room> roomController =
      SingleSelectController(null);
  late SingleSelectController<Day> dayController = SingleSelectController(null);
  late SingleSelectController<Time> timeController =
      SingleSelectController(null);
  late SingleSelectController<Semester> semesterController =
      SingleSelectController(null);

  List<Time> lastSelectedTimes = [];
  List<Day> lastSelectedDays = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightThemeData,
      darkTheme: darkThemeData,
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
                                    decoration: InputDecoration(
                                      hintText: 'Benutzername eingeben',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 12.0),
                                      constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  TextField(
                                    obscureText: true,
                                    controller: passwordController,
                                    decoration: InputDecoration(
                                      hintText: 'Kennwort eingeben',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 12.0),
                                      constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2.0),
                              ElevatedButton(
                                onPressed: () async {
                                  await login(
                                      username: usernameController.text,
                                      password: passwordController.text);
                                  if (context.mounted) {
                                    FocusScope.of(context).unfocus();
                                  }
                                  {
                                    sanitizeDropdownOptions(
                                        context.mounted == true
                                            ? context
                                            : context,
                                        (await fetchTimetable())!
                                            .data
                                            .toString());
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
                                      CustomDropdown<Lecturer>.search(
                                        controller: lecturerController,
                                        decoration:
                                            const CustomDropdownDecoration(
                                          listItemDecoration:
                                              ListItemDecoration(
                                            selectedColor: Color.fromARGB(
                                                180, 255, 224, 153),
                                          ),
                                          headerStyle: TextStyle(
                                            fontSize: 16,
                                            color: Color(
                                              0xFFEF6C00,
                                            ),
                                          ),
                                          expandedFillColor: Color(0xFFFBEFE2),
                                          prefixIcon: Icon(Icons.person_search),
                                          searchFieldDecoration:
                                              SearchFieldDecoration(
                                            prefixIcon:
                                                Icon(Icons.manage_search),
                                          ),
                                        ),
                                        hintText: 'Dozent/in',
                                        items: lecturers.values.toList(),
                                        excludeSelected: false,
                                        onChanged: (value) {
                                          log('changing value to: $value');
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      CustomDropdown<Room>.search(
                                        controller: roomController,
                                        decoration:
                                            const CustomDropdownDecoration(
                                          listItemDecoration:
                                              ListItemDecoration(
                                            selectedColor: Color.fromARGB(
                                                180, 255, 224, 153),
                                          ),
                                          headerStyle: TextStyle(
                                            fontSize: 16,
                                            color: Color(
                                              0xFFEF6C00,
                                            ),
                                          ),
                                          expandedFillColor: Color(0xFFFBEFE2),
                                          prefixIcon:
                                              Icon(Icons.class_outlined),
                                          searchFieldDecoration:
                                              SearchFieldDecoration(
                                            prefixIcon:
                                                Icon(Icons.manage_search),
                                          ),
                                        ),
                                        hintText: 'Raum',
                                        items: rooms.values.toList(),
                                        excludeSelected: false,
                                        onChanged: (value) {
                                          log('changing value to: $value');
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      CustomDropdown<Day>(
                                        controller: dayController,
                                        decoration:
                                            const CustomDropdownDecoration(
                                          listItemDecoration:
                                              ListItemDecoration(
                                            selectedColor: Color.fromARGB(
                                                180, 255, 224, 153),
                                          ),
                                          headerStyle: TextStyle(
                                            fontSize: 16,
                                            color: Color(
                                              0xFFEF6C00,
                                            ),
                                          ),
                                          expandedFillColor: Color(0xFFFBEFE2),
                                          prefixIcon: Icon(Icons.sunny_snowing),
                                        ),
                                        hintText: 'Tag',
                                        items: days.values.toList(),
                                        excludeSelected: false,
                                        onChanged: (value) {
                                          log('changing value to: $value');
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      CustomDropdown<Time>(
                                        decoration:
                                            const CustomDropdownDecoration(
                                          listItemDecoration:
                                              ListItemDecoration(
                                            selectedColor: Color.fromARGB(
                                                180, 255, 224, 153),
                                          ),
                                          headerStyle: TextStyle(
                                            fontSize: 16,
                                            color: Color(
                                              0xFFEF6C00,
                                            ),
                                          ),
                                          expandedFillColor: Color(0xFFFBEFE2),
                                          prefixIcon: Icon(Icons.av_timer),
                                          searchFieldDecoration:
                                              SearchFieldDecoration(
                                            prefixIcon:
                                                Icon(Icons.manage_search),
                                          ),
                                        ),
                                        hintText: 'Zeit',
                                        items: times.values.toList(),
                                        controller: timeController,
                                        excludeSelected: false,
                                        onChanged: (value) {},
                                      ),
                                      const SizedBox(height: 8),
                                      CustomDropdown<Semester>.search(
                                        controller: semesterController,
                                        decoration:
                                            const CustomDropdownDecoration(
                                          listItemDecoration:
                                              ListItemDecoration(
                                            selectedColor: Color.fromARGB(
                                                180, 255, 224, 153),
                                          ),
                                          headerStyle: TextStyle(
                                            fontSize: 16,
                                            color: Color(
                                              0xFFEF6C00,
                                            ),
                                          ),
                                          expandedFillColor: Color(0xFFFBEFE2),
                                          prefixIcon: Icon(Icons.school),
                                          searchFieldDecoration:
                                              SearchFieldDecoration(
                                            prefixIcon:
                                                Icon(Icons.manage_search),
                                          ),
                                        ),
                                        hintText: 'Semester',
                                        items: semesters.values.toList(),
                                        excludeSelected: false,
                                        onChanged: (value) {
                                          log('changing value to: $value');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              ElevatedButton(
                                onPressed: () async {
                                  await searchTable();
                                  // swipe page
                                  pageIndicatorController.animateToPage(
                                    1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeIn,
                                  );
                                },
                                child: const Text('Suchen'),
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
                        CustomCalendar(classSessions: classSessions),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                left: 0,
                bottom: 10,
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

  final pageIndicatorController =
      PageController(viewportFraction: 1, initialPage: 0);
}

List<String> tableData = [];
List<ClassSession> classSessions = [];

List<ClassSession> parseToClassSessions(List<String> data) {
  List<ClassSession> sessions = [];
  String? dozent, veranstaltung, tag, zeit, raum;
  int i = 0;

  for (String info in data) {
    if (i == 0) {
      dozent = info;
    } else if (i == 1) {
      veranstaltung = info;
    } else if (i == 2) {
      tag = info;
    } else if (i == 3) {
      zeit = info;
    } else if (i == 4) {
      raum = info;

      sessions.add(ClassSession(
        dozent: dozent!,
        veranstatlung: veranstaltung!,
        tag: tag!,
        zeit: zeit!,
        raum: raum,
      ));

      i = -1;
    }

    i++;
  }

  return sessions;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

extension E on String {
  String lastChars(int n) => substring(0, length - n);
}
