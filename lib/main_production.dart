import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/bootstrap.dart';

Future<void> main() async {
  await dotenv.load();
  await bootstrap(() => const App());
}
