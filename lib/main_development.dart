import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(
    () => const Directionality(
      textDirection: TextDirection.ltr,
      child: Banner(
        message: 'Dev',
        location: BannerLocation.topEnd,
        child: App(),
      ),
    ),
    initialize: () => dotenv.load(fileName: '.env.dev'),
  );
}
