import 'package:meteo_app/data/database/app_database.dart';
import 'package:meteo_app/data/models/city_model.dart';
class CityDA0 {
  Future<int> insertCity(City city) async {
    final db = await AppDatabase.instance.database; // Connexion à la base de donnee
    return await db.insert('cities', city.toMap()); // Dis à SQLLITE d'ajouter une ligne dans la table cities. On peut pas stocker un objet dart dans une base donnee dou le toMap()
  }

  Future<void> updateCity(City city) async {
    final db = await AppDatabase.instance.database; // Connexion à la base de donnee
    await db.update('cities', city.toMap(),where: 'id = ?', // (1)
      whereArgs: [city.id],);
  }
}

Future<void> deleteCity(int id) async {
  final db = await AppDatabase.instance.database;
  await db.delete(
    'cities',
    where: 'id = ?',
    whereArgs: [id],
  );
}

