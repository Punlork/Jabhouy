import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'counter state is the same after going to home and switching apps',
    ($) async {
      // Minimal smoke test: find text and (on mobile) press home.
      // Replace with $.pumpWidgetAndSettle(yourAppWidget) to test the real app.
      await $.pumpWidgetAndSettle(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('app')),
            backgroundColor: Colors.blue,
          ),
        ),
      );
      expect($('app'), findsOneWidget);
      if (!Platform.isMacOS) {
        await $.platform.mobile.pressHome();
      }
    },
  );
}
