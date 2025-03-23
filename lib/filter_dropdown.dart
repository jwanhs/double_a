import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';

class FilterDropdown<T> extends StatelessWidget {
  final SingleSelectController<T> controller;
  final List<T> items;
  final String hintText;
  final String? searchHintText;
  final bool enabled;
  final Icon prefixIcon;
  final bool useSearch;
  final Function(T?)? onChanged;

  const FilterDropdown({
    super.key,
    required this.controller,
    required this.items,
    required this.hintText,
    required this.prefixIcon,
    this.searchHintText,
    this.enabled = true,
    this.useSearch = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> elevation = [
      const BoxShadow(
        color: Color.fromARGB(90, 0, 0, 0),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ];

    final decoration = CustomDropdownDecoration(
      expandedShadow: elevation,
      listItemDecoration: const ListItemDecoration(
        selectedColor: Color.fromARGB(180, 255, 224, 153),
      ),
      headerStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFFEF6C00),
      ),
      expandedFillColor: const Color(0xFFFBEFE2),
      prefixIcon: prefixIcon,
      searchFieldDecoration: useSearch
          ? const SearchFieldDecoration(
              prefixIcon: Icon(Icons.manage_search),
            )
          : null,
    );

    if (useSearch) {
      return CustomDropdown<T>.search(
        enabled: enabled,
        controller: controller,
        decoration: decoration,
        searchHintText: searchHintText ?? 'Suchen',
        hintText: hintText,
        items: items,
        excludeSelected: false,
        onChanged: onChanged ?? (_) {},
        noResultFoundText: 'Kein Ergebnis gefunden',
      );
    } else {
      return CustomDropdown<T>(
        enabled: enabled,
        controller: controller,
        decoration: decoration,
        hintText: hintText,
        items: items,
        excludeSelected: false,
        onChanged: onChanged ?? (_) {},
      );
    }
  }
}
