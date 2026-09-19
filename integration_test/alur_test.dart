// Alur end-to-end yang sama dengan test/alur_test.dart, tapi dijalankan di
// emulator/HP asli (binding integration_test). Jalankan:
//   flutter test integration_test -d <device>
import 'package:integration_test/integration_test.dart';

import '../test/alur_test.dart' as alur;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  alur.main();
}
