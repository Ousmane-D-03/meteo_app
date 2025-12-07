import 'package:meteo_app/data/database/app_database.dart';
import 'package:meteo_app/data/models/place_model.dart';

class PlaceDAO {
  Future<int> insertPlace(Place place) async {
    final db = await AppDatabase.instance.database; // Connexion à la base de donnee
    return await db.insert('places', place.toMap()); // Dis à SQLLITE d'ajouter une ligne dans la table places. On peut pas stocker un objet dart dans une base donnee dou le toMap()
  }

  Future<void> updatePlace(Place place) async {
    final db = await AppDatabase.instance.database; // Connexion à la base de donnee
    await db.update('places', place.toMap(),where: 'id = ?', // (1)
      whereArgs: [place.id],);
  }

  Future<void> deletePlace(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'places',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}