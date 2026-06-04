import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class CouponKeeperDatabase {
  CouponKeeperDatabase({
    this.databaseFactory,
    Future<String> Function()? databasePath,
  }) : _databasePath = databasePath ?? _defaultDatabasePath;

  static const int schemaVersion = 1;

  final DatabaseFactory? databaseFactory;
  final Future<String> Function() _databasePath;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final path = await _databasePath();
    final factory = databaseFactory;
    final opened = factory == null
        ? await openDatabase(
            path,
            version: schemaVersion,
            onCreate: _createSchema,
          )
        : await factory.openDatabase(
            path,
            options: OpenDatabaseOptions(
              version: schemaVersion,
              onCreate: _createSchema,
            ),
          );
    _database = opened;
    return opened;
  }

  Future<void> close() async {
    final existing = _database;
    _database = null;
    await existing?.close();
  }

  static Future<String> _defaultDatabasePath() async {
    final root = await getDatabasesPath();
    return p.join(root, 'coupon_keeper.db');
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
CREATE TABLE passes (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  brand TEXT,
  estimated_value INTEGER,
  expiry TEXT,
  status TEXT NOT NULL,
  source_original_uri TEXT NOT NULL,
  source_platform_type TEXT NOT NULL,
  source_fingerprint TEXT NOT NULL,
  source_imported_at TEXT NOT NULL,
  source_is_available INTEGER NOT NULL,
  source_missing_reason TEXT,
  image_copy_path TEXT,
  ocr_text TEXT,
  confidence_expiry REAL NOT NULL,
  confidence_value REAL NOT NULL,
  confidence_brand REAL NOT NULL,
  confidence_barcode REAL NOT NULL,
  confidence_overall REAL NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE scan_fingerprints (
  fingerprint TEXT PRIMARY KEY,
  seen_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE image_copies (
  fingerprint TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
)
''');
  }
}
