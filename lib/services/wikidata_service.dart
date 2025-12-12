import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service pour récupérer les informations des villes depuis Wikidata
/// 
/// Wikidata est une base de données libre et ouverte
/// API utilisée : https://www.wikidata.org/w/api.php
class WikidataService {
  
  /// Récupère les informations détaillées d'une ville
  /// 
  /// [cityName] : Le nom de la ville (ex: "Paris", "Lyon")
  /// 
  /// Retourne un Map avec toutes les infos ou null si erreur
  static Future<Map<String, dynamic>?> fetchCityInfo(String cityName) async {
    try {
      // ÉTAPE 1 : Chercher l'ID Wikidata de la ville
      final wikidataId = await _searchCityWikidataId(cityName);
      
      if (wikidataId == null) {
        print('Ville "$cityName" non trouvée sur Wikidata');
        return null;
      }
      
      print('ID Wikidata trouvé : $wikidataId');
      
      // ÉTAPE 2 : Récupérer toutes les infos détaillées avec cet ID
      final cityData = await _fetchCityDetails(wikidataId);
      
      return cityData;
      
    } catch (e) {
      print('Erreur WikidataService : $e');
      return null;
    }
  }
  
  /// Recherche l'ID Wikidata d'une ville par son nom
  /// 
  /// Exemple : "Paris" → "Q90" (ID Wikidata de Paris)
  static Future<String?> _searchCityWikidataId(String cityName) async {
    // Construction de l'URL de recherche Wikidata
    final url = Uri.parse(
      'https://www.wikidata.org/w/api.php?'
      'action=wbsearchentities&'  // Action : rechercher des entités
      'search=$cityName&'          // Le nom à rechercher
      'language=fr&'               // Langue : français
      'format=json'                // Format de réponse : JSON
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // On prend le premier résultat (le plus pertinent)
        if (data['search'] != null && data['search'].isNotEmpty) {
          return data['search'][0]['id']; // Ex: "Q90" pour Paris
        }
      }
    } catch (e) {
      print('Erreur recherche Wikidata : $e');
    }
    
    return null;
  }
  
  /// Récupère tous les détails d'une ville avec son ID Wikidata
  /// 
  /// [wikidataId] : L'identifiant Wikidata (ex: "Q90" pour Paris)
  static Future<Map<String, dynamic>?> _fetchCityDetails(String wikidataId) async {
    // Construction de l'URL pour récupérer toutes les propriétés
    final url = Uri.parse(
      'https://www.wikidata.org/w/api.php?'
      'action=wbgetentities&'      // Action : récupérer des entités
      'ids=$wikidataId&'           // L'ID de la ville
      'languages=fr&'              // Langue : français
      'format=json'                // Format : JSON
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Les données sont dans entities > [wikidataId]
        if (data['entities'] != null && data['entities'][wikidataId] != null) {
          final entity = data['entities'][wikidataId];
          
          // Parser et structurer les données importantes
          return _parseEntityData(entity);
        }
      }
    } catch (e) {
      print('Erreur récupération détails : $e');
    }
    
    return null;
  }
  
  /// Parse les données brutes de Wikidata et extrait les infos importantes
  /// 
  /// Structure Wikidata :
  /// - labels : les noms dans différentes langues
  /// - descriptions : les descriptions
  /// - claims : toutes les propriétés (population, superficie, etc.)
  static Map<String, dynamic> _parseEntityData(Map<String, dynamic> entity) {
    final claims = entity['claims'] ?? {};
    
    return {
      // Nom de la ville
      'name': entity['labels']?['fr']?['value'] ?? 'Nom inconnu',
      
      // Description
      'description': entity['descriptions']?['fr']?['value'] ?? 'Pas de description disponible',
      
      // Population (P1082)
      'population': _extractPropertyValue(claims, 'P1082'),
      
      // Superficie en km² (P2046)
      'area': _extractPropertyValue(claims, 'P2046'),
      
      // Altitude en mètres (P2044)
      'altitude': _extractPropertyValue(claims, 'P2044'),
      
      // Coordonnées (P625)
      'coordinates': _extractCoordinates(claims),
      
      // Pays (P17)
      'country': _extractPropertyLabel(claims, 'P17'),
      
      // Maire (P6) - chef de l'exécutif
      'mayor': _extractPropertyLabel(claims, 'P6'),
      
      // Date de fondation (P571)
      'founded': _extractPropertyValue(claims, 'P571'),
      
      // Site web officiel (P856)
      'website': _extractPropertyValue(claims, 'P856'),
      
      // Image (P18)
      'image': _extractImage(claims),
      
      
    };
  }
  
  /// Extrait une valeur simple d'une propriété Wikidata
  /// 
  /// [claims] : Toutes les propriétés de l'entité
  /// [propertyId] : L'ID de la propriété (ex: "P1082" pour population)
  static String? _extractPropertyValue(Map<String, dynamic> claims, String propertyId) {
    try {
      if (claims[propertyId] != null && claims[propertyId].isNotEmpty) {
        final value = claims[propertyId][0]['mainsnak']['datavalue']['value'];
        
        // Si c'est un nombre, le formater joliment
        if (value is num) {
          return value.toString();
        }
        
        // Si c'est un objet avec 'amount' (comme la population)
        if (value is Map && value['amount'] != null) {
          return value['amount'].toString().replaceAll('+', '');
        }
        
        // Si c'est du texte
        if (value is String) {
          return value;
        }
      }
    } catch (e) {
      print(' Erreur extraction propriété $propertyId : $e');
    }
    return null;
  }
  
  /// Extrait le label (nom) d'une propriété qui pointe vers une autre entité
  /// 
  /// Exemple : Pour "Pays", on veut "France" et pas "Q142"
  static String? _extractPropertyLabel(Map<String, dynamic> claims, String propertyId) {
    try {
      if (claims[propertyId] != null && claims[propertyId].isNotEmpty) {
        final value = claims[propertyId][0]['mainsnak']['datavalue']['value'];
        
        // Si c'est une entité (avec un ID), on prend son label
        if (value is Map && value['id'] != null) {
          // On pourrait faire une autre requête pour récupérer le label
          // Mais pour simplifier, on va juste retourner l'ID pour l'instant
          // TODO: Améliorer en faisant une requête pour le label
          return value['id'];
        }
      }
    } catch (e) {
      print('Erreur extraction label $propertyId : $e');
    }
    return null;
  }
  
  /// Extrait les coordonnées géographiques (latitude, longitude)
  static Map<String, double>? _extractCoordinates(Map<String, dynamic> claims) {
    try {
      if (claims['P625'] != null && claims['P625'].isNotEmpty) {
        final value = claims['P625'][0]['mainsnak']['datavalue']['value'];
        
        if (value is Map) {
          return {
            'latitude': (value['latitude'] as num).toDouble(),
            'longitude': (value['longitude'] as num).toDouble(),
          };
        }
      }
    } catch (e) {
      print('Erreur extraction coordonnées : $e');
    }
    return null;
  }
  
  /// Extrait l'URL de l'image principale de la ville
  /// 
  /// Wikidata stocke le nom du fichier, pas l'URL complète
  /// Il faut construire l'URL Wikimedia Commons
  static String? _extractImage(Map<String, dynamic> claims) {
    try {
      if (claims['P18'] != null && claims['P18'].isNotEmpty) {
        final filename = claims['P18'][0]['mainsnak']['datavalue']['value'];
        
        if (filename is String) {
          // Construire l'URL Wikimedia Commons
          // Format : https://commons.wikimedia.org/wiki/Special:FilePath/[filename]
          final encodedFilename = Uri.encodeComponent(filename);
          return 'https://commons.wikimedia.org/wiki/Special:FilePath/$encodedFilename?width=800';
        }
      }
    } catch (e) {
      print('Erreur extraction image : $e');
    }
    return null;
  }
}
