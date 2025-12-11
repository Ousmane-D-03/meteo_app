import 'package:meteo_app/database/models/cache.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

const String tableName = 'places';

class Placeprovider {
  final String tableName = 'favorites';
  Database? db;
  // Ouverture de la base de données
  Future open() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "places.db"); // ✔ nouveau nom
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL ,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            cityName TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Ajoutez ici les méthodes CRUD
  //Methode insert
  Future<Place> insert(Place place) async {
    place.id = await db!.insert(tableName, place.toMap());
    return place;
  }
  //Methode getPlace
  Future<Place> getPlace(int id) async {
    List<Map<String, dynamic>> maps = await db!.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Place.fromMap(maps.first);
    }
    throw Exception('ID $id not found');
  }

  //Methode update
  Future<int> update(Place place) async {
    return await db!.update(
      tableName,
      place.toMap(),
      where: 'id = ?',
      whereArgs: [place.id],
    );
  }

  //Methode delete
  Future<int> delete(int id) async {
    return await db!.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //Methode getAllplaces
  Future<List<Place>> getAllPlaces() async {
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    return maps.map((map) => Place.fromMap(map)).toList();
  }
  Future close() async => db!.close();
}