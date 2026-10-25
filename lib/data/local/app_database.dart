import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scan_record.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ecomind_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );

    await _ensureColumnsExist(db);
    return db;
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    await _ensureColumnsExist(db);
  }

  Future<void> _ensureColumnsExist(Database db) async {
    try {
      final columnsInfo = await db.rawQuery('PRAGMA table_info(items)');
      final columnNames = columnsInfo.map((row) => row['name'] as String).toSet();

      if (!columnNames.contains('surfaceTexture')) {
        await db.execute('ALTER TABLE items ADD COLUMN surfaceTexture TEXT;');
      }
      if (!columnNames.contains('edgeDensity')) {
        await db.execute('ALTER TABLE items ADD COLUMN edgeDensity REAL;');
      }
    } catch (_) {}
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        originalImagePath TEXT NOT NULL,
        enhancedImagePath TEXT NOT NULL,
        detectorVersion TEXT NOT NULL,
        classifierVersion TEXT NOT NULL,
        totalElapsedMs INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        scanId TEXT NOT NULL,
        box_left REAL NOT NULL,
        box_top REAL NOT NULL,
        box_right REAL NOT NULL,
        box_bottom REAL NOT NULL,
        predictedClass TEXT NOT NULL,
        confidence REAL NOT NULL,
        detectorScore REAL NOT NULL,
        contaminationRatio REAL,
        contaminationLevel TEXT,
        glassColor TEXT,
        surfaceTexture TEXT,
        edgeDensity REAL,
        cropImagePath TEXT,
        maskImagePath TEXT,
        correctedClass TEXT,
        FOREIGN KEY (scanId) REFERENCES scans (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE corrections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId TEXT NOT NULL,
        scanId TEXT NOT NULL,
        originalClass TEXT NOT NULL,
        correctedClass TEXT NOT NULL,
        detectorScore REAL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertScan(ScanRecord scan) async {
    final db = await instance.database;
    await db.insert('scans', scan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (final item in scan.items) {
      await db.insert('items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> recordCorrection({
    required String itemId,
    required String scanId,
    required String originalClass,
    required String correctedClass,
    double? detectorScore,
  }) async {
    final db = await instance.database;
    await db.update(
      'items',
      {'correctedClass': correctedClass},
      where: 'id = ?',
      whereArgs: [itemId],
    );

    await db.insert('corrections', {
      'itemId': itemId,
      'scanId': scanId,
      'originalClass': originalClass,
      'correctedClass': correctedClass,
      'detectorScore': detectorScore,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getScansHistory({int limit = 50}) async {
    final db = await instance.database;
    return await db.query('scans', orderBy: 'timestamp DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getItemsForScan(String scanId) async {
    final db = await instance.database;
    return await db.query('items', where: 'scanId = ?', whereArgs: [scanId]);
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await instance.database;
    final totalScans = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM scans')) ?? 0;
    final totalItems = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM items')) ?? 0;
    final totalCorrections = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM corrections')) ?? 0;

    return {
      'totalScans': totalScans,
      'totalItems': totalItems,
      'totalCorrections': totalCorrections,
    };
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('corrections');
    await db.delete('items');
    await db.delete('scans');
  }
}

