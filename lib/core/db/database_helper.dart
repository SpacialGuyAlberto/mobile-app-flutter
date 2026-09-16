import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "quarkbau_cache.db";
  static const _databaseVersion = 1;

  static const tableCache = 'local_cache';

  static const columnId = 'id';
  static const columnType = 'entity_type';
  static const columnPayload = 'json_payload';
  static const columnLastSynced = 'last_synced';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableCache (
            $columnId TEXT NOT NULL,
            $columnType TEXT NOT NULL,
            $columnPayload TEXT NOT NULL,
            $columnLastSynced INTEGER NOT NULL,
            PRIMARY KEY ($columnId, $columnType)
          )
          ''');
  }

  Future<void> upsertCache(String id, String entityType, String jsonPayload) async {
    final db = await database;
    final row = {
      columnId: id,
      columnType: entityType,
      columnPayload: jsonPayload,
      columnLastSynced: DateTime.now().millisecondsSinceEpoch,
    };
    await db.insert(
      tableCache,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCacheByType(String entityType) async {
    final db = await database;
    return await db.query(
      tableCache,
      where: '$columnType = ?',
      whereArgs: [entityType],
    );
  }

  Future<void> clearCacheByType(String entityType) async {
    final db = await database;
    await db.delete(
      tableCache,
      where: '$columnType = ?',
      whereArgs: [entityType],
    );
  }
}
