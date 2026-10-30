import 'package:flutter_test/flutter_test.dart';
import 'package:owner/database/pot/pot_verification_report.dart';
import 'package:owner/main_pot.dart';

void main() {
  testWidgets('PotDiagnosticApp renders PASS summary card', (
    WidgetTester tester,
  ) async {
    const sampleReport = PotVerificationReport(
      platform: 'windows',
      buildMode: 'debug',
      sqliteVersion: '3.49.1',
      activeCipher: 'chacha20',
      lifecycleRoundtripPassed: true,
      rawFileEncryptedPassed: true,
      wrongKeyRejectedNotadbPassed: true,
      failClosedGuardPassed: true,
      durationMs: 42,
    );

    await tester.pumpWidget(const PotDiagnosticApp(report: sampleReport));

    expect(
      find.text('PASS — All 4 SQLite Encryption Checks Verified'),
      findsOneWidget,
    );
    expect(find.text('chacha20'), findsOneWidget);
  });
}
