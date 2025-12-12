import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service pour récupérer les informations depuis Wikipedia (français)
/// 
/// Ce service permet de récupérer :
/// - L'historique/résumé d'une ville
/// - La liste des monuments liés
/// - Les détails d'un monument avec son image
class WikipediaService {
  static const String _baseUrl = 'https://fr.wikipedia.org/w/api.php';
  
  /// Récupère toutes les informations d'une ville depuis Wikipedia
  /// 
  /// [cityName] : Le nom de la ville (ex: "Paris", "Lyon")
  /// 
  /// Retourne un Map contenant :
  /// - history : l'historique de la ville
  /// - monuments : liste des monuments avec leurs détails
  static Future<Map<String, dynamic>?> fetchCityCompleteInfo(String cityName) async {
    try {
      print('Récupération des infos Wikipedia pour : $cityName');
      
      // ÉTAPE 1 : Récupérer l'historique de la ville
      final history = await fetchCityHistory(cityName);
      
      if (history == null) {
        print('Historique non trouvé pour $cityName');
        return null;
      }
      
      // ÉTAPE 2 : Récupérer la liste des monuments liés
      final monumentNames = await fetchCityMonuments(cityName);
      
      // ÉTAPE 3 : Récupérer les détails de chaque monument
      final monuments = <Map<String, dynamic>>[];
      
      // Limiter à 10 monuments pour ne pas surcharger
      final limitedMonuments = monumentNames.take(10).toList();
      
      for (final monumentName in limitedMonuments) {
        print('Chargement du monument : $monumentName');
        final monumentDetails = await fetchMonumentDetails(monumentName);
        
        if (monumentDetails != null) {
          monuments.add(monumentDetails);
        }
        
        // Petite pause pour ne pas surcharger l'API
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      print('Infos Wikipedia récupérées : ${monuments.length} monuments');
      
      return {
        'history': history,
        'monuments': monuments,
      };
      
    } catch (e) {
      print('Erreur WikipediaService : $e');
      return null;
    }
  }
  
  /// Récupère l'historique/résumé d'une ville
  /// 
  /// API utilisée :
  /// https://fr.wikipedia.org/w/api.php?action=query&titles=Paris&prop=extracts&exintro&explaintext&format=json
  /// 
  /// Paramètres :
  /// - action=query : faire une requête
  /// - titles=Paris : titre de la page
  /// - prop=extracts : récupérer l'extrait
  /// - exintro : seulement l'introduction
  /// - explaintext : en texte brut (pas de HTML)
  /// - format=json : réponse en JSON
  static Future<String?> fetchCityHistory(String cityName) async {
    final url = Uri.parse(
      '$_baseUrl?'
      'action=query&'
      'titles=$cityName&'
      'prop=extracts&'
      'exintro&'
      'explaintext&'
      'format=json'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Structure : query → pages → [pageId] → extract
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        
        if (pages != null && pages.isNotEmpty) {
          // Récupérer la première (et normalement unique) page
          final page = pages.values.first;
          
          // Vérifier que la page existe (pas de pageId = -1)
          if (page['pageid'] != null && page['pageid'] != -1) {
            final extract = page['extract'] as String?;
            
            if (extract != null && extract.isNotEmpty) {
              return extract;
            }
          }
        }
      }
    } catch (e) {
      print('Erreur fetchCityHistory : $e');
    }
    
    return null;
  }
  
  /// Récupère la liste des monuments/lieux liés à une ville
  /// 
  /// API utilisée :
  /// https://fr.wikipedia.org/w/api.php?action=query&titles=Paris&prop=links&pllimit=max&format=json
  /// 
  /// Paramètres :
  /// - action=query : faire une requête
  /// - titles=Paris : titre de la page
  /// - prop=links : récupérer les liens
  /// - pllimit=max : maximum de liens
  /// - format=json : réponse en JSON
  /// 
  /// Filtre les liens pour ne garder que les monuments (ns:0 = articles)
  static Future<List<String>> fetchCityMonuments(String cityName) async {
    final url = Uri.parse(
      '$_baseUrl?'
      'action=query&'
      'titles=$cityName&'
      'prop=links&'
      'pllimit=max&'
      'format=json'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Structure : query → pages → [pageId] → links
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        
        if (pages != null && pages.isNotEmpty) {
          final page = pages.values.first;
          final links = page['links'] as List?;
          
          if (links != null) {
            // Filtrer les liens pour ne garder que les articles (ns:0)
            // et exclure les liens trop génériques
            final monumentNames = links
                .where((link) => 
                    link['ns'] == 0 && // Namespace 0 = article
                    _isLikelyMonument(link['title']))
                .map((link) => link['title'] as String)
                .toList();
            
            print('🔗 ${monumentNames.length} liens trouvés pour $cityName');
            return monumentNames;
          }
        }
      }
    } catch (e) {
      print('Erreur fetchCityMonuments : $e');
    }
    
    return [];
  }
  
  /// Filtre pour identifier les monuments potentiels
  /// 
  /// Garde les liens qui contiennent des mots-clés de monuments
  /// et exclut les liens trop génériques
  static bool _isLikelyMonument(String title) {
    // Mots-clés pour identifier les monuments
    final monumentKeywords = [
      'église', 'cathédrale', 'basilique', 'abbaye',
      'château', 'palais', 'hôtel',
      'tour', 'pont', 'arc',
      'musée', 'théâtre', 'opéra',
      'place', 'jardin', 'parc',
      'gare', 'stade', 'arène',
      'monument', 'mémorial',
      'fort', 'citadelle',
    ];
    
    // Mots à exclure (liens trop génériques)
    final excludeKeywords = [
      'liste', 'catégorie', 'portail',
      'histoire', 'géographie',
      'arrondissement', 'quartier',
      'bibliographie', 'références',
      'voir aussi', 'article',
    ];
    
    final lowerTitle = title.toLowerCase();
    
    // Exclure si contient un mot interdit
    if (excludeKeywords.any((word) => lowerTitle.contains(word))) {
      return false;
    }
    
    // Garder si contient un mot-clé de monument
    return monumentKeywords.any((word) => lowerTitle.contains(word));
  }
  
  /// Récupère les détails complets d'un monument
  /// 
  /// API utilisée :
  /// https://fr.wikipedia.org/w/api.php?action=query&titles=Tour%20Eiffel&prop=extracts|pageimages&exintro&piprop=original&format=json
  /// 
  /// Paramètres :
  /// - action=query : faire une requête
  /// - titles=Tour Eiffel : titre du monument
  /// - prop=extracts|pageimages : récupérer l'extrait ET l'image
  /// - exintro : seulement l'introduction
  /// - piprop=original : URL de l'image originale
  /// - format=json : réponse en JSON
  /// 
  /// Retourne :
  /// - name : nom du monument
  /// - description : description du monument
  /// - imageUrl : URL de l'image
  static Future<Map<String, dynamic>?> fetchMonumentDetails(String monumentName) async {
    final url = Uri.parse(
      '$_baseUrl?'
      'action=query&'
      'titles=$monumentName&'
      'prop=extracts|pageimages&'
      'exintro&'
      'explaintext&'
      'piprop=original&'
      'format=json'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Structure : query → pages → [pageId]
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        
        if (pages != null && pages.isNotEmpty) {
          final page = pages.values.first;
          
          // Vérifier que la page existe
          if (page['pageid'] != null && page['pageid'] != -1) {
            final name = page['title'] as String?;
            final description = page['extract'] as String?;
            final imageUrl = page['original']?['source'] as String?;
            
            // Ne retourner que si on a au moins un nom et une description
            if (name != null && description != null && description.isNotEmpty) {
              return {
                'name': name,
                'description': _truncateDescription(description),
                'imageUrl': imageUrl,
              };
            }
          }
        }
      }
    } catch (e) {
      print('Erreur fetchMonumentDetails pour $monumentName : $e');
    }
    
    return null;
  }
  
  /// Tronque une description si elle est trop longue
  /// 
  /// Garde uniquement les 3 premières phrases (environ)
  static String _truncateDescription(String description) {
    // Limiter à 500 caractères
    if (description.length <= 500) {
      return description;
    }
    
    // Couper à la première phrase complète après 300 caractères
    final cutPoint = description.indexOf('.', 300);
    
    if (cutPoint != -1 && cutPoint < 600) {
      return description.substring(0, cutPoint + 1);
    }
    
    // Sinon, couper à 500 caractères
    return '${description.substring(0, 500)}...';
  }
  
  /// Récupère l'image principale d'une page Wikipedia
  /// 
  /// Utile pour récupérer juste l'image d'une ville sans autres détails
  static Future<String?> fetchPageImage(String pageName) async {
    final url = Uri.parse(
      '$_baseUrl?'
      'action=query&'
      'titles=$pageName&'
      'prop=pageimages&'
      'piprop=original&'
      'format=json'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        
        if (pages != null && pages.isNotEmpty) {
          final page = pages.values.first;
          return page['original']?['source'] as String?;
        }
      }
    } catch (e) {
      print('Erreur fetchPageImage : $e');
    }
    
    return null;
  }
}
