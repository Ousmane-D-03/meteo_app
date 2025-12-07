import 'package:meteo_app/data/database/app_database.dart';
import 'package:meteo_app/data/models/comment_model.dart';

class CommentDAO {
  Future<int> insertComment(Comment comment) async {
    final db = await AppDatabase.instance.database; // Connexion à la base de donnee
    return await db.insert('comments', comment.toMap()); // Dis à SQLLITE d'ajouter une ligne dans la table comments. On peut pas stocker un objet dart dans une base donnee dou le toMap()
  }

  Future<void> updateComment(Comment comment) async {
    final db = await AppDatabase.instance.database; // Connexion à la base de donnee
    await db.update('comments', comment.toMap(),where: 'id = ?', // (1)
      whereArgs: [comment.id],);
  }
  Future<void> deleteComment(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'comments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

