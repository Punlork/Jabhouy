import 'package:flutter/material.dart';

/// Hands each tab its own `ScrollController`.
///
/// Declared inside `home_page.dart` and read by shop, loaner and income,
/// so three features imported the home barrel for one InheritedWidget.
class TabScrollManager extends InheritedWidget {
  const TabScrollManager({
    required this.controllers,
    required super.child,
    super.key,
  });

  final List<ScrollController> controllers;

  static TabScrollManager? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabScrollManager>();
  }

  @override
  bool updateShouldNotify(TabScrollManager oldWidget) {
    return controllers != oldWidget.controllers;
  }

  ScrollController getController(int index) => controllers[index];
}
