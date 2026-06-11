import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'requerimientos_ti.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla para guardar módulos cacheados
    await db.execute('''
      CREATE TABLE modules_cache(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');

    // Tabla para guardar requests (tickets) cacheados
    await db.execute('''
      CREATE TABLE requests_cache(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');

    // Tabla para cola de pending requests (creados offline)
    await db.execute('''
      CREATE TABLE pending_requests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT
      )
    ''');
  }

  // --- Operaciones Módulos ---
  Future<void> saveModulesCache(List<Map<String, dynamic>> modulesData) async {
    final db = await database;
    await db.delete('modules_cache'); // Limpiar caché vieja
    Batch batch = db.batch();
    for (var doc in modulesData) {
      batch.insert('modules_cache', {
        'id': doc['id'],
        'data': jsonEncode(doc) // Usar jsonEncode en lugar de toString()
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getModulesCache() async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query('modules_cache');
    return maps;
  }

  // --- Operaciones Requests ---
  Future<void> saveRequestsCache(List<Map<String, dynamic>> requestsData, String cacheType) async {
    final db = await database;
    // Podríamos usar diferentes tablas para user_requests y all_requests, o un campo extra. 
    // Para simplificar, usaremos la misma tabla y reescribiremos. 
    // (O mejor, no vaciamos, insertamos con ON CONFLICT REPLACE).
    Batch batch = db.batch();
    for (var doc in requestsData) {
      batch.insert('requests_cache', {
        'id': doc['id'],
        'data': jsonEncode(doc)
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getRequestsCache() async {
    final db = await database;
    return await db.query('requests_cache');
  }

  // --- Operaciones Cola Pendiente ---
  Future<void> addPendingRequest(String jsonData) async {
    final db = await database;
    await db.insert('pending_requests', {'data': jsonData});
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final db = await database;
    return await db.query('pending_requests');
  }

  Future<void> removePendingRequest(int id) async {
    final db = await database;
    await db.delete('pending_requests', where: 'id = ?', whereArgs: [id]);
  }
}
