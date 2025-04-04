import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:upgrader/upgrader.dart';

class AppUpgrader extends StatelessWidget {
  const AppUpgrader({
    required this.child,
    super.key,
    this.showIgnore = true,
    this.showLater = true,
  });
  final Widget child;
  final bool showIgnore;
  final bool showLater;

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      navigatorKey: AppRoutes.router.routerDelegate.navigatorKey,
      upgrader: Upgrader(
        debugDisplayAlways: true,
        minAppVersion: '1.0.1',
      ),
      child: child,
    );
  }
}
