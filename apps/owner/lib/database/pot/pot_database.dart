import 'package:drift/drift.dart';

part 'pot_database.g.dart';

/// Isolated Sprint 1.1 Proof-of-Technology probe table (`pot_probe_records`).
///
/// Intentionally contains zero production domain tables (`venues`, `halls`,
/// `reservations`, `payments`, etc.) to keep the encryption PoT strictly
/// isolated (`FR-006`, `FR-012`).
@DataClassName('PotProbeRecord')
class PotProbeRecords extends Table {
  @override
  String get tableName => 'pot_probe_records';

  /// UUIDv4 primary key.
  TextColumn get id => text()();

  /// Known high-entropy UTF-8 sentinel string scanned for in raw on-disk
  /// byte inspection (`FR-008`, `SC-002`).
  TextColumn get sentinelText => text().named('sentinel_text')();

  /// Arabic (`ar-DZ` RTL) UTF-8 probe text (`Principle IV`).
  TextColumn get localeSampleAr => text().named('locale_sample_ar')();

  /// French (`fr-DZ` LTR) UTF-8 probe text (`Principle IV`).
  TextColumn get localeSampleFr => text().named('locale_sample_fr')();

  /// English (`en` LTR) UTF-8 probe text (`Principle IV`).
  TextColumn get localeSampleEn => text().named('locale_sample_en')();

  /// Whole-integer Algerian Dinar amount (`BIGINT` / `INTEGER` `DZD`,
  /// `Principle VI`).
  IntColumn get amountDzd => integer().named('amount_dzd')();

  /// ISO-8601 UTC timestamp string (`YYYY-MM-DDTHH:mm:ssZ`).
  TextColumn get createdAtUtc => text().named('created_at_utc')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Minimal Drift database wrapping only [PotProbeRecords] over an encrypted
/// `sqlite3mc` (`chacha20`) connection.
@DriftDatabase(tables: <Type>[PotProbeRecords])
class PotDatabase extends _$PotDatabase {
  PotDatabase(super.e);

  @override
  int get schemaVersion => 1;

  /// Inserts a single [PotProbeRecord] row into `pot_probe_records`.
  Future<int> insertProbeRecord(PotProbeRecord record) =>
      into(potProbeRecords).insert(record);

  /// Fetches a [PotProbeRecord] by its primary key [id], or `null` if absent.
  Future<PotProbeRecord?> getProbeRecordById(String id) =>
      (select(potProbeRecords)..where((PotProbeRecords tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  /// Runs `PRAGMA integrity_check;` and returns the first row result
  /// (expected: `'ok'`).
  Future<String> runIntegrityCheck() async {
    final row = await customSelect('PRAGMA integrity_check;').getSingle();
    return row.data.values.first?.toString() ?? '';
  }
}
