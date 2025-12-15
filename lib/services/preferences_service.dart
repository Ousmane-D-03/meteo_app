import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les préférences utilisateur
/// 
/// Utilise SharedPreferences pour sauvegarder :
/// - La ville par défaut
/// - Les coordonnées de la ville
/// - L'historique des recherches
class PreferencesService {
  // Clés pour SharedPreferences
  static const String _keyDefaultCity = 'default_city_name';
  static const String _keyDefaultLat = 'default_city_lat';
  static const String _keyDefaultLon = 'default_city_lon';
  
  /// Sauvegarde la ville par défaut avec ses coordonnées
  /// 
  /// [cityName] : Nom de la ville (ex: "Paris")
  /// [lat] : Latitude
  /// [lon] : Longitude
  /// 
  /// Exemple :
  /// ```dart
  /// await PreferencesService.setDefaultCity('Paris', 48.8566, 2.3522);
  /// ```
  static Future<bool> setDefaultCity(String cityName, double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder les 3 valeurs
      await prefs.setString(_keyDefaultCity, cityName);
      await prefs.setDouble(_keyDefaultLat, lat);
      await prefs.setDouble(_keyDefaultLon, lon);
      
      print('Ville par défaut sauvegardée : $cityName');
      return true;
    } catch (e) {
      print('Erreur sauvegarde ville par défaut : $e');
      return false;
    }
  }
  
  /// Récupère la ville par défaut
  /// 
  /// Retourne un Map avec :
  /// - cityName : nom de la ville
  /// - lat : latitude
  /// - lon : longitude
  /// 
  /// Retourne null si aucune ville par défaut n'est définie
  static Future<Map<String, dynamic>?> getDefaultCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cityName = prefs.getString(_keyDefaultCity);
      final lat = prefs.getDouble(_keyDefaultLat);
      final lon = prefs.getDouble(_keyDefaultLon);
      
      // Vérifier que toutes les valeurs existent
      if (cityName != null && lat != null && lon != null) {
        print('Ville par défaut trouvée : $cityName');
        print(lat);
        print(lon);
        return {
          'cityName': cityName,
          'lat': lat,
          'lon': lon,
        };
      }
      
      print('ℹAucune ville par défaut définie');
      return null;
    } catch (e) {
      print('Erreur récupération ville par défaut : $e');
      return null;
    }
  }
  
  /// Supprime la ville par défaut
  static Future<bool> clearDefaultCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyDefaultCity);
      await prefs.remove(_keyDefaultLat);
      await prefs.remove(_keyDefaultLon);
      
      print('Ville par défaut supprimée');
      return true;
    } catch (e) {
      print('Erreur suppression ville par défaut : $e');
      return false;
    }
  }
  
  /// Vérifie si une ville par défaut est définie
  static Future<bool> hasDefaultCity() async {
    final defaultCity = await getDefaultCity();
    return defaultCity != null;
  }
  

}