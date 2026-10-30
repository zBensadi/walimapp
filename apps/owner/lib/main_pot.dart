import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'database/pot/pot_verification_report.dart';
import 'database/pot/sqlite_encryption_pot_suite.dart';

const bool _kPotAutoExit = bool.fromEnvironment('POT_AUTO_EXIT');
const String _kPotReportFilePath = String.fromEnvironment('POT_REPORT_FILE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Directory? baseDir;
  try {
    baseDir = await getTemporaryDirectory();
  } on Object {
    baseDir = Directory.systemTemp;
  }

  final report = await SqliteEncryptionPotSuite.runAllChecks(
    parentTempDir: baseDir,
  );

  // Emit single-line machine-readable JSON report to stdout/logcat (`FR-010`).
  // ignore: avoid_print
  print(report.toStdoutLine());

  if (_kPotReportFilePath.isNotEmpty) {
    try {
      final reportFile = File(_kPotReportFilePath);
      reportFile.parent.createSync(recursive: true);
      reportFile.writeAsStringSync('${report.toStdoutLine()}\n');
    } on Object {
      // Ignore file-write errors in restricted sandboxes.
    }
  }

  runApp(PotDiagnosticApp(report: report));

  if (_kPotAutoExit) {
    Timer(const Duration(milliseconds: 1500), () {
      exit(report.allPassed ? 0 : 1);
    });
  }
}

/// Minimal diagnostic surface displaying the SQLite encryption PoT results.
class PotDiagnosticApp extends StatelessWidget {
  const PotDiagnosticApp({required this.report, super.key});

  final PotVerificationReport report;

  @override
  Widget build(BuildContext context) {
    final passed = report.allPassed;
    return MaterialApp(
      title: 'WalimApp SQLite Encryption PoT',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: passed ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        appBar: AppBar(
          title: const Text('WalimApp — SQLite3MC (ChaCha20) PoT'),
          backgroundColor: passed ? const Color(0xFF166534) : const Color(0xFF991B1B),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              margin: const EdgeInsets.all(24),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        passed
                            ? 'PASS — All 4 SQLite Encryption Checks Verified'
                            : 'FAIL — SQLite Encryption Verification Failed',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: passed
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF991B1B),
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildRow('Platform', report.platform),
                      _buildRow('Build Mode', report.buildMode),
                      _buildRow('SQLite Version', report.sqliteVersion),
                      _buildRow('Pre-Key Active Cipher', report.activeCipher),
                      _buildRow(
                        'Check 1 — Lifecycle Round-Trip (US1)',
                        report.lifecycleRoundtripPassed ? 'PASS' : 'FAIL',
                      ),
                      _buildRow(
                        'Check 2 — Raw On-Disk Ciphertext (US2)',
                        report.rawFileEncryptedPassed ? 'PASS' : 'FAIL',
                      ),
                      _buildRow(
                        'Check 3 — Wrong-Key SQLITE_NOTADB (US3)',
                        report.wrongKeyRejectedNotadbPassed ? 'PASS' : 'FAIL',
                      ),
                      _buildRow(
                        'Check 4 — Unconditional Fail-Closed Guard (US1)',
                        report.failClosedGuardPassed ? 'PASS' : 'FAIL',
                      ),
                      _buildRow(
                        'Duration (Informational SC-004)',
                        '${report.durationMs} ms',
                      ),
                      if (report.errorDetail != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          'Error Detail:\n${report.errorDetail}',
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
