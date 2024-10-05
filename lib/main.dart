import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:dio/dio.dart';
import 'package:double_a/dio_singleton.dart';
import 'package:double_a/models.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

Dio dio = DioSingleton.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
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
        log('POST successful');
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

    try {
      dom.Document document = html_parser.parse(htmlString);

      for (var table in document.querySelectorAll('table')) {
        for (var row in table.querySelectorAll('tr')) {
          for (var cell in row.querySelectorAll('td')) {
            log(cell.text);
          }
        }
      }
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

  Map<dynamic, Lecturer> lecturers = {"%": const Lecturer("All Lecturers")};
  Map<dynamic, Room> rooms = {"%": const Room("All Rooms")};
  Map<dynamic, Day> days = {"%": const Day("All Days")};
  Map<dynamic, Time> times = {"%": const Time("All Times")};
  Map<dynamic, Semester> semesters = {"%": const Semester("All Semesters")};

  void sanitizeDropdownOptions(String htmlString) {
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

      lecturers[lecturers.keys.first] = const Lecturer("All Lecturers");
      lecturerController.value = lecturers.values.first;
      rooms[rooms.keys.first] = const Room("All Rooms");
      rooms.remove(rooms.keys.elementAt(1));
      roomController.value = rooms.values.first;
      days[days.keys.first] = const Day("All Days");
      dayController.value = days.values.first;
      // lastSelectedDays = days.values.toList();
      times[times.keys.first] = const Time("All Times");
      timeController.value = times.values.first;
      // lastSelectedTimes = times.values.toList();
      semesters[semesters.keys.first] = const Semester("All Semesters");
      semesterController.value = semesters.values.first;

      setState(() {});
    } catch (e) {
      log('Error parsing options: $e');
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your username',
                ),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await login(
                      username: usernameController.text,
                      password: passwordController.text);
                  sanitizeDropdownOptions(
                      (await fetchTimetable())!.data.toString());
                },
                child: const Text('Login'),
              ),
              CustomDropdown<Lecturer>.search(
                controller: lecturerController,
                decoration: const CustomDropdownDecoration(
                  prefixIcon: Icon(Icons.person_search),
                  searchFieldDecoration: SearchFieldDecoration(
                    prefixIcon: Icon(Icons.manage_search),
                  ),
                ),
                hintText: 'Lecturer',
                items: lecturers.values.toList(),
                excludeSelected: false,
                onChanged: (value) {
                  log('changing value to: $value');
                },
              ),
              CustomDropdown<Room>.search(
                controller: roomController,
                decoration: const CustomDropdownDecoration(
                  prefixIcon: Icon(Icons.class_outlined),
                  searchFieldDecoration: SearchFieldDecoration(
                    prefixIcon: Icon(Icons.manage_search),
                  ),
                ),
                hintText: 'Room',
                items: rooms.values.toList(),
                excludeSelected: false,
                onChanged: (value) {
                  log('changing value to: $value');
                },
              ),
              CustomDropdown<Day>(
                controller: dayController,
                decoration: const CustomDropdownDecoration(
                  prefixIcon: Icon(Icons.sunny_snowing),
                ),
                hintText: 'Day',
                items: days.values.toList(),
                excludeSelected: false,
                onChanged: (value) {
                  log('changing value to: $value');
                },
              ),
              CustomDropdown<Time>(
                decoration: const CustomDropdownDecoration(
                  prefixIcon: Icon(Icons.av_timer),
                  searchFieldDecoration: SearchFieldDecoration(
                    prefixIcon: Icon(Icons.manage_search),
                  ),
                ),
                hintText: 'Time',
                items: times.values.toList(),
                controller: timeController,
                excludeSelected: false,
                onChanged: (value) {},
              ),
              CustomDropdown<Semester>.search(
                controller: semesterController,
                decoration: const CustomDropdownDecoration(
                  prefixIcon: Icon(Icons.school),
                  searchFieldDecoration: SearchFieldDecoration(
                    prefixIcon: Icon(Icons.manage_search),
                  ),
                ),
                hintText: 'Semester',
                items: semesters.values.toList(),
                excludeSelected: false,
                onChanged: (value) {
                  log('changing value to: $value');
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  searchTable();
                },
                child: const Text('Search'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
