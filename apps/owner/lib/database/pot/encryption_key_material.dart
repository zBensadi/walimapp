import 'dart:typed_data';

/// Validated 256-bit (`32-byte`) symmetric encryption key material for `sqlite3mc`.
///
/// Enforces exact 64-character hexadecimal input (`^[0-9a-fA-F]{64}$`) before any
/// SQLite connection or `PRAGMA key` statement is executed (`FR-004`).
final class EncryptionKeyMaterial {
  EncryptionKeyMaterial._(this._bytes);

  static final RegExp _hex64Pattern = RegExp(r'^[0-9a-fA-F]{64}$');

  final Uint8List _bytes;
  bool _isDisposed = false;

  /// Parses and validates a 64-character hexadecimal string representing a
  /// 32-byte (`256-bit`) symmetric key.
  ///
  /// Throws [ArgumentError] immediately if [hexKey] is empty, has length != 64,
  /// contains non-hexadecimal characters, or decodes to anything other than
  /// 32 bytes.
  factory EncryptionKeyMaterial.fromHex(String hexKey) {
    if (hexKey.isEmpty) {
      throw ArgumentError.value(
        '<empty>',
        'hexKey',
        'Encryption key must be a 64-character hexadecimal string (32 bytes); received empty string.',
      );
    }
    if (hexKey.length != 64) {
      throw ArgumentError.value(
        '<len:${hexKey.length}>',
        'hexKey',
        'Encryption key must be exactly 64 hexadecimal characters (32 bytes); received length ${hexKey.length}.',
      );
    }
    if (!_hex64Pattern.hasMatch(hexKey)) {
      throw ArgumentError.value(
        '<redacted>',
        'hexKey',
        'Encryption key must contain only hexadecimal characters [0-9a-fA-F].',
      );
    }

    final bytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      final byteHex = hexKey.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(byteHex, radix: 16);
    }
    if (bytes.lengthInBytes != 32) {
      throw ArgumentError.value(
        '<redacted>',
        'hexKey',
        'Decoded key material must be exactly 32 bytes.',
      );
    }
    return EncryptionKeyMaterial._(bytes);
  }

  /// Whether [dispose] has been called to zero the in-memory key buffer.
  bool get isDisposed => _isDisposed;

  /// Length of the decoded key in bytes (always `32`).
  int get lengthInBytes => _bytes.lengthInBytes;

  /// Formats the validated key as an SQLite blob literal (`x'<64-lowercase-hex>'`)
  /// suitable for `PRAGMA key = "x'...'";`.
  ///
  /// Throws [StateError] if this key material has already been disposed.
  String toSqliteBlobLiteral() {
    _ensureNotDisposed();
    final buffer = StringBuffer("x'");
    for (final byte in _bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    buffer.write("'");
    return buffer.toString();
  }

  /// Overwrites the internal 32-byte key buffer with zeros.
  void dispose() {
    if (!_isDisposed) {
      _bytes.fillRange(0, _bytes.length, 0);
      _isDisposed = true;
    }
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'EncryptionKeyMaterial has already been disposed and cannot be used.',
      );
    }
  }

  @override
  String toString() =>
      'EncryptionKeyMaterial(256-bit, isDisposed: $_isDisposed)';
}
