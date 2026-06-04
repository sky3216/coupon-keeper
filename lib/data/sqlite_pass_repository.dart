import '../domain/pass.dart';
import '../domain/pass_confidence.dart';
import '../domain/pass_source_metadata.dart';
import 'coupon_keeper_database.dart';
import 'pass_repository.dart';

class SqlitePassRepository implements PassRepository {
  SqlitePassRepository(this._database);

  final CouponKeeperDatabase _database;

  @override
  Future<void> save(Pass pass) async {
    final db = await _database.database;
    await db.insert('passes', _toRow(pass));
  }

  @override
  Future<void> update(Pass pass) async {
    final db = await _database.database;
    await db.update(
      'passes',
      _toRow(pass),
      where: 'id = ?',
      whereArgs: [pass.id],
    );
  }

  @override
  Future<void> deleteById(String id) async {
    final db = await _database.database;
    await db.delete('passes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Pass?> getById(String id) async {
    final db = await _database.database;
    final rows = await db.query('passes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.single);
  }

  @override
  Future<List<Pass>> listAll() async {
    final db = await _database.database;
    final rows = await db.query('passes', orderBy: 'created_at ASC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Pass>> listByStoredStatus(PassStatus status) async {
    final db = await _database.database;
    final rows = await db.query(
      'passes',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Pass>> listByEffectiveStatus(
    PassStatus status,
    DateTime today,
  ) async {
    final passes = await listAll();
    return passes
        .where((pass) => pass.effectiveStatus(today) == status)
        .toList();
  }

  @override
  Future<List<Pass>> listActive(DateTime today) {
    return listByEffectiveStatus(PassStatus.active, today);
  }

  @override
  Future<List<Pass>> listUsed() {
    return listByStoredStatus(PassStatus.used);
  }

  @override
  Future<List<Pass>> listExpired(DateTime today) {
    return listByEffectiveStatus(PassStatus.expired, today);
  }

  @override
  Future<List<Pass>> listCleanupCandidates() {
    return listByStoredStatus(PassStatus.cleanupCandidate);
  }

  @override
  Future<List<Pass>> listNeedsReview() {
    return listByStoredStatus(PassStatus.needsReview);
  }

  Map<String, Object?> _toRow(Pass pass) {
    return {
      'id': pass.id,
      'type': pass.type.name,
      'title': pass.title,
      'brand': pass.brand,
      'estimated_value': pass.estimatedValue,
      'expiry': pass.expiry?.toIso8601String(),
      'status': pass.status.name,
      'source_original_uri': pass.sourceMetadata.originalUri,
      'source_platform_type': pass.sourceMetadata.platformSourceType,
      'source_fingerprint': pass.sourceMetadata.fingerprint,
      'source_imported_at': pass.sourceMetadata.importedAt.toIso8601String(),
      'source_is_available': pass.sourceMetadata.isAvailable ? 1 : 0,
      'source_missing_reason': pass.sourceMetadata.missingReason,
      'image_copy_path': pass.imageCopyPath,
      'ocr_text': pass.ocrText,
      'confidence_expiry': pass.confidence.expiry,
      'confidence_value': pass.confidence.value,
      'confidence_brand': pass.confidence.brand,
      'confidence_barcode': pass.confidence.barcode,
      'confidence_overall': pass.confidence.overall,
      'created_at': pass.createdAt.toIso8601String(),
      'updated_at': pass.updatedAt.toIso8601String(),
    };
  }

  Pass _fromRow(Map<String, Object?> row) {
    return Pass(
      id: row['id']! as String,
      type: PassType.values.byName(row['type']! as String),
      title: row['title']! as String,
      brand: row['brand'] as String?,
      estimatedValue: row['estimated_value'] as int?,
      expiry: _parseDate(row['expiry'] as String?),
      status: PassStatus.values.byName(row['status']! as String),
      sourceMetadata: PassSourceMetadata(
        originalUri: row['source_original_uri']! as String,
        platformSourceType: row['source_platform_type']! as String,
        fingerprint: row['source_fingerprint']! as String,
        importedAt: DateTime.parse(row['source_imported_at']! as String),
        isAvailable: (row['source_is_available']! as int) == 1,
        missingReason: row['source_missing_reason'] as String?,
      ),
      imageCopyPath: row['image_copy_path'] as String?,
      ocrText: row['ocr_text'] as String?,
      confidence: PassConfidence(
        expiry: row['confidence_expiry']! as double,
        value: row['confidence_value']! as double,
        brand: row['confidence_brand']! as double,
        barcode: row['confidence_barcode']! as double,
        overall: row['confidence_overall']! as double,
      ),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  DateTime? _parseDate(String? value) {
    return value == null ? null : DateTime.parse(value);
  }
}
