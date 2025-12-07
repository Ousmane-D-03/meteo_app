import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  // --- Singleton ---
  AppDatabase._privateConstructor();
  static final AppDatabase instance = AppDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- Initialize DB ---
  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, "explore_ville.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // --- Create tables ---
  Future<void> _onCreate(Database db, int version) async {
    await db.execute("""
      CREATE TABLE cities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        lat REAL,
        lng REAL,
        country TEXT
      );
    """);

    await db.execute("""
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cityId INTEGER,
        name TEXT,
        category TEXT,
        description TEXT,
        lat REAL,
        lng REAL,
        imagePath TEXT,
        FOREIGN KEY(cityId) REFERENCES cities(id)
      );
    """);

    await db.execute("""
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        placeId INTEGER,
        text TEXT,
        rating INTEGER,
        date TEXT,
        FOREIGN KEY(placeId) REFERENCES places(id)
      );
    """);

    await db.execute("""
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        placeId INTEGER,
        createdAt TEXT,
        FOREIGN KEY(placeId) REFERENCES places(id)
      );
    """);
  }
}
