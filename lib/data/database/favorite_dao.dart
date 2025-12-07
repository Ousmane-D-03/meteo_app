import 'package:sqflite/sqflite.dart';
import 'package:meteo_app/data/database/app_database.dart';
import 'package:meteo_app/data/models/favorite_model.dart';

class FavoriteDAO {
  Future<int> insertFavorite(Favorite favorite) async {
    final db = await AppDatabase.instance.database; // Connexion à la base de donnee
    return await db.insert('favorites', favorite.toMap()); // Dis à SQLLITE d'ajouter une ligne dans la table favorites. On peut pas stocker un objet dart dans une base donnee dou le toMap()
  }

  Future<void> updateFavorite(Favorite favorite) async {
    final db = await AppDatabase.instance.database; // Connexion à la base de donnee
    await db.update('favorites', favorite.toMap(),where: 'id = ?', // (1)
      whereArgs: [favorite.id],);
  }

  Future<void> deleteFavorite(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}