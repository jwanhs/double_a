import 'package:animated_custom_dropdown/custom_dropdown.dart';

class FilterableItem with CustomDropdownListFilter {
  final String name;
  const FilterableItem(this.name);

  @override
  String toString() => name;

  @override
  bool filter(String query) => name.toLowerCase().contains(query.toLowerCase());
}

class Lecturer extends FilterableItem {
  const Lecturer(super.name);
}

class Semester extends FilterableItem {
  const Semester(super.name);
}

class Room extends FilterableItem {
  const Room(super.name);
}

class Day extends FilterableItem {
  const Day(super.name);
}

class Time extends FilterableItem {
  const Time(super.name);
}

class Class {
  final String dozent;
  final String veranstatlung;
  final String tag;
  final String zeit;
  final String raum;

  const Class({
    required this.dozent,
    required this.veranstatlung,
    required this.tag,
    required this.zeit,
    required this.raum,
  });
}
