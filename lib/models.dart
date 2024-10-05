
import 'package:animated_custom_dropdown/custom_dropdown.dart';

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

class Semester with CustomDropdownListFilter {
  final String name;
  const Semester(this.name);

  @override
  String toString() {
    return name;
  }

  @override
  bool filter(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}

class Room with CustomDropdownListFilter {
  final String name;
  const Room(this.name);

  @override
  String toString() {
    return name;
  }

  @override
  bool filter(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}

class Day with CustomDropdownListFilter {
  final String name;
  const Day(this.name);

  @override
  String toString() {
    return name;
  }

  @override
  bool filter(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}

class Time with CustomDropdownListFilter {
  final String name;
  const Time(this.name);

  @override
  String toString() {
    return name;
  }

  @override
  bool filter(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}

class ClassSession {
  final String dozent;
  final String veranstatlung;
  final String tag;
  final String zeit;
  final String raum;

  ClassSession({
    required this.dozent,
    required this.veranstatlung,
    required this.tag,
    required this.zeit,
    required this.raum,
  });
}