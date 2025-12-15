import 'package:flutter/material.dart';
import 'package:meteo_app/database/models/favori.dart';
import 'package:meteo_app/database/providers/favori_provider.dart';

class FavoriteNotifier extends ChangeNotifier {
  final FavoriteProvider _db = FavoriteProvider();
  List<Favorite> _favorites = [];

  List<Favorite> get favorites => _favorites;

  /// Initialisation : ouvre la DB et charge les favoris
  Future<void> init() async {
    await _db.open();
    _favorites = await _db.getAllFavorites();
    notifyListeners();
  }

  /// Vérifie si un lieu ou une ville est en favori
  bool isFavorite(String name) {
    return _favorites.any((f) => f.name == name && f.isFavorite);
  }

  /// Toggle d’un favori
  Future<void> toggleFavorite(Favorite fav) async {
    if (fav.id == null) {
      // Nouvel élément
      fav.isFavorite = true;
      await _db.insert(fav);
      _favorites.add(fav);
    } else {
      // Élement existant : inverse le statut
      fav.isFavorite = !fav.isFavorite;
      await _db.update(fav);
      int index = _favorites.indexWhere((f) => f.id == fav.id);
      if (index != -1) _favorites[index] = fav;
    }
    notifyListeners();
  }

  /// Sauvegarder une liste de POI pour une ville
  Future<void> savePoi(List<Map<String, dynamic>> pois, String city) async {
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

  List<Map<String, dynamic>> get favoritePlacesMap {
    return _favorites
        .where((fav) => fav.isFavorite) // garde uniquement les favoris
        .map((fav) {
      IconData icon;
      List<Color> gradient;

      switch (fav.category) {
        case 'Parcs':
          icon = Icons.park;
          gradient = [Colors.greenAccent, Colors.lightGreen];
          break;
        case 'Restaurants':
          icon = Icons.restaurant;
          gradient = [Colors.orangeAccent, Colors.deepOrange];
          break;
        case 'Musées':
          icon = Icons.museum;
          gradient = [Colors.purpleAccent, Colors.deepPurple];
          break;
        case 'Gares':
          icon = Icons.train;
          gradient = [Colors.redAccent, Colors.red];
          break;
        case 'Universités':
          icon = Icons.school;
          gradient = [Colors.tealAccent, Colors.teal];
          break;
        default:
          icon = Icons.place;
          gradient = [Colors.blueAccent, Colors.lightBlue];
      }

      return {
        'name': fav.name,
        'icon': icon,
        'gradient': gradient,
      };
    }).toList();
  }


  /// Recharge la liste depuis la base de données
  Future<void> loadFavorites() async {
    _favorites = await _db.getAllFavorites();
    notifyListeners();
  }

  /// Supprime un favori
  Future<void> deleteFavorite(Favorite fav) async {
    if (fav.id != null) {
      await _db.delete(fav.id!);
      _favorites.removeWhere((f) => f.id == fav.id);
      notifyListeners();
    }
  }
}
