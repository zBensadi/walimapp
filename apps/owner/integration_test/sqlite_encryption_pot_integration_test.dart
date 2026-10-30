import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:owner/database/pot/sqlite_encryption_pot_suite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SQLite3MC (ChaCha20-Poly1305) end-to-end encryption PoT passes all 4 checks',
    (WidgetTester tester) async {
      final report = await SqliteEncryptionPotSuite.runAllChecks();
      // ignore: avoid_print
      print(report.toStdoutLine());

      expect(report.errorDetail, isNull);
      expect(report.activeCipher, equals('chacha20'));
      expect(report.lifecycleRoundtripPassed, isTrue);
      expect(report.rawFileEncryptedPassed, isTrue);
      expect(report.wrongKeyRejectedNotadbPassed, isTrue);
      expect(report.failClosedGuardPassed, isTrue);
      expect(report.allPassed, isTrue);
    },
  );
}
