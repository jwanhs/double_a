import 'dart:developer';
import 'dart:io';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:dio/dio.dart';
import 'package:double_a/dio_singleton.dart';
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

    log('Timetable Data:');
    log(timetableResponse.data.toString());
    return timetableResponse;
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

  @override
  void initState() {
    super.initState();
  }

  List<String> lecturers = ["Select All"];
  List<String> rooms = ["Select All"];
  List<String> days = ["Select All"];
  List<String> times = ["Select All"];
  List<String> semesters = ["Select All"];

  void sanitizeDropdownOptions(String htmlString) {
    if (htmlString.isEmpty) {
      log('Result body empty');
    }

    try {
      dom.Document document = html_parser.parse(htmlString);

      for (var lecturerOptions
          in document.querySelectorAll('select[name="lecturer_nr"] option')) {
        if (lecturerOptions.attributes['value'] != '%') {
          lecturers.add(lecturerOptions.text.trim());
        }
      }

      for (var roomOptions
          in document.querySelectorAll('select[name="room_nr"] option')) {
        rooms.add(roomOptions.text.trim());
      }

      for (var dayOptions
          in document.querySelectorAll('select[name="day_nr"] option')) {
        days.add(dayOptions.text.trim());
      }

      for (var timeOptions
          in document.querySelectorAll('select[name="time_nr"] option')) {
        times.add(timeOptions.text.trim());
      }

      for (var semesterOptions in document
          .querySelectorAll('select[name="semestergroup_nr"] option')) {
        semesters.add(semesterOptions.text.trim());
      }

      setState(() {});
    } catch (e) {
      log('Error parsing options: $e');
    }
  }

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
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
            DropdownButton<String>(
              hint: const Text('Select Lecturer'),
              items: lecturers.map((String lecturer) {
                return DropdownMenuItem<String>(
                  value: lecturer,
                  child: Text(lecturer),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {});
              },
            ),
            DropdownButton<String>(
              hint: const Text('Select Room'),
              items: rooms.map((String room) {
                return DropdownMenuItem<String>(
                  value: room,
                  child: Text(room),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {});
              },
            ),
            DropdownButton<String>(
              hint: const Text('Select Day'),
              items: days.map((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {});
              },
            ),
            DropdownButton<String>(
              hint: const Text('Select Time'),
              items: times.map((String time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {});
              },
            ),
            DropdownButton<String>(
              hint: const Text('Select Semester'),
              items: semesters.map((String semester) {
                return DropdownMenuItem<String>(
                  value: semester,
                  child: Text(semester),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {});
              },
            ),
          ],
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

class Lecturer with CustomDropdownListFilter {
  final String name;
  const Lecturer(this.name);

  @override
  String toString() {
    return name;
  }

  @override
  bool filter(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}
