import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/bootstrap.dart';

void main() {
  bootstrap(() async {
    await dotenv.load();
    return const App();
  });
}
