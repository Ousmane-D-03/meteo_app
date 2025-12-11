import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:meteo_app/database/models/favori.dart';
class FavoriteProvider {
  final String tableName = 'favorites';
  Database? db;

  Future<void> open() async {
    db = await openDatabase(
      'favorite.db',
      version: 2,
      onCreate: (db, version) {
        return db.execute('''
        CREATE TABLE favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          city TEXT NOT NULL,
          isFavorite INTEGER NOT NULL DEFAULT 0
        )
      ''');
      },
    );
  }

  Future<bool> isFavorite(String name) async {
      List<Map<String, dynamic>> maps = await db!.query(
        tableName,
        where: 'name = ?',
        whereArgs: [name],
      );
      return maps.isNotEmpty;
    }
  Future<void> toggleFavorite(Favorite fav) async {
    fav.isFavorite = !fav.isFavorite;
    await db!.update('favorites', fav.toMap(),
        where: 'id = ?', whereArgs: [fav.id]);
  }

    Future<Favorite> insert(Favorite fav) async {
      fav.id = await db!.insert(tableName, fav.toMap());
      return fav;
    }

    Future<Favorite> getFavorite(int id) async {
      List<Map<String, dynamic>> maps = await db!.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Favorite.fromMap(maps.first);
      }
      throw Exception('ID $id not found');
    }
    Future<int> delete(int id) async {
      return await db!.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    Future<int> update(Favorite fav) async {
      return await db!.update(
        tableName,
        fav.toMap(),
        where: 'id = ?',
        whereArgs: [fav.id],
      );
    }

  Future<List<Favorite>> getAllFavorites() async {
    if (db == null) {
      await open(); // ouvre la base si pas déjà ouverte
    }
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    return maps.map((map) => Favorite.fromMap(map)).toList();
  }




  Future close() async => db!.close();

  }