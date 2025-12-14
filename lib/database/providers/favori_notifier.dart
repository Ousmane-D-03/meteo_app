import 'package:flutter/foundation.dart';
import 'package:meteo_app/database/models/favori.dart';
import 'package:meteo_app/database/providers/favori_provider.dart';

class FavoriteNotifier extends ChangeNotifier {
  final FavoriteProvider _db = FavoriteProvider();
  List<Favorite> _favorites = [];

  List<Favorite> get favorites => _favorites;

  Future init() async {
    await _db.open();
    _favorites = await _db.getAllFavorites();
    notifyListeners();
  }

  bool isFavorite(String name) {
    return _favorites.any((f) => f.name == name && f.isFavorite);
  }


  // Toggle simple d'un favori
  Future toggleFavorite(Favorite fav) async {
    fav.isFavorite = !fav.isFavorite;
    await _db.update(fav);
    notifyListeners();
  }


  Future toggleFavorite1(Favorite fav) async {
    if (fav.id == null) {
      await _db.insert(fav);
      _favorites.add(fav);
    } else {
      // Mets à jour exactement l'état de fav.isFavorite
      await _db.update(fav);
      int index = _favorites.indexWhere((f) => f.id == fav.id);
      if (index != -1) _favorites[index] = fav;
    }
    notifyListeners();
  }
  /// Nouvelle fonction pour sauvegarder une liste de POI
  Future savePoi(List<Map<String, dynamic>> pois, String city) async {
    for (var poi in pois) {
      bool exists = _favorites.any((f) => f.name == poi['name']);
      if (!exists) {
        Favorite newFav = Favorite(
          name: poi['name'],
          latitude: poi['latitude'],
          longitude: poi['longitude'],
          city: city,
          category: poi['category'] ?? 'Autre',
          isFavorite: false,
        );
        await _db.insert(newFav);
        _favorites.add(newFav);
      }
    }
    notifyListeners();
  }

}
