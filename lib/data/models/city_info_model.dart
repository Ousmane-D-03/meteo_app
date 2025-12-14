/// Modèle de données pour les informations détaillées d'une ville
/// 
/// Ce modèle structure toutes les données provenant de Wikidata ET Wikipedia
/// et les rend facilement manipulables dans Flutter
class CityInfo {
  final String name;
  final String description;
  final String? population;
  final String? area;
  final String? altitude;
  final double? latitude;
  final double? longitude;
  final String? country;
  final String? mayor;
  final String? founded;
  final String? website;
  final String? imageUrl;
  final String? history;  
  final List<Monument> monuments;

  CityInfo({
    required this.name,
    required this.description,
    this.population,
    this.area,
    this.altitude,
    this.latitude,
    this.longitude,
    this.country,
    this.mayor,
    this.founded,
    this.website,
    this.imageUrl,
    this.history, 
    this.monuments = const [],
  });

  /// Crée un objet CityInfo depuis un Map JSON
  /// 
  /// Cette méthode est appelée après avoir récupéré les données
  /// du WikidataService ET du WikipediaService
  factory CityInfo.fromJson(Map<String, dynamic> json) {
    // Extraction des coordonnées
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final lat = coords?['latitude'] as double?;
    final lon = coords?['longitude'] as double?;

    // Formatage de la population (ajouter des espaces pour la lisibilité)
    String? formattedPopulation;
    if (json['population'] != null) {
      final pop = json['population'].toString().replaceAll('+', '').replaceAll('.0', '');
      formattedPopulation = _formatNumber(pop);
    }

    // Formatage de la superficie
    String? formattedArea;
    if (json['area'] != null) {
      final area = json['area'].toString().replaceAll('.0', '');
      formattedArea = '$area km²';
    }

    // Formatage de l'altitude
    String? formattedAltitude;
    if (json['altitude'] != null) {
      final alt = json['altitude'].toString().replaceAll('.0', '');
      formattedAltitude = '$alt m';
    }

    // Formatage de la date de fondation
    String? formattedFounded;
    if (json['founded'] != null) {
      formattedFounded = _formatDate(json['founded']);
    }

    return CityInfo(
      name: json['name'] ?? 'Nom inconnu',
      description: json['description'] ?? 'Pas de description disponible',
      population: formattedPopulation,
      area: formattedArea,
      altitude: formattedAltitude,
      latitude: lat,
      longitude: lon,
      country: json['country'],
      mayor: json['mayor'],
      founded: formattedFounded,
      website: json['website'],
      imageUrl: json['image'],
      history: json['history'], 
      monuments: (json['monuments'] as List?)
              ?.map((m) => Monument.fromJson(m))
              .toList() ??
          [],
    );
  }

  /// Convertit l'objet CityInfo en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'population': population,
      'area': area,
      'altitude': altitude,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'mayor': mayor,
      'founded': founded,
      'website': website,
      'image': imageUrl,
      'history': history,  
      'monuments': monuments.map((m) => m.toJson()).toList(),
    };
  }

  /// Formate un nombre avec des espaces pour la lisibilité
  static String _formatNumber(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanNumber.isEmpty) return number;
    
    final reversed = cleanNumber.split('').reversed.join();
    final chunks = <String>[];
    
    for (int i = 0; i < reversed.length; i += 3) {
      final end = i + 3;
      chunks.add(reversed.substring(i, end > reversed.length ? reversed.length : end));
    }
    
    return chunks.join(' ').split('').reversed.join();
  }

  /// Formate une date Wikidata en format lisible
  static String _formatDate(dynamic date) {
    if (date == null) return 'Date inconnue';
    
    final dateStr = date.toString();
    
    if (dateStr.contains('T')) {
      final year = dateStr.substring(1, 5);
      return year;
    }
    
    if (dateStr.length >= 4) {
      return dateStr.replaceAll('+', '').substring(0, 4);
    }
    
    return dateStr;
  }

  /// Crée une copie de l'objet avec certains champs modifiés
  CityInfo copyWith({
    String? name,
    String? description,
    String? population,
    String? area,
    String? altitude,
    double? latitude,
    double? longitude,
    String? country,
    String? mayor,
    String? founded,
    String? website,
    String? imageUrl,
    String? history,  
    List<Monument>? monuments,
  }) {
    return CityInfo(
      name: name ?? this.name,
      description: description ?? this.description,
      population: population ?? this.population,
      area: area ?? this.area,
      altitude: altitude ?? this.altitude,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      mayor: mayor ?? this.mayor,
      founded: founded ?? this.founded,
      website: website ?? this.website,
      imageUrl: imageUrl ?? this.imageUrl,
      history: history ?? this.history,  
      monuments: monuments ?? this.monuments,
    );
  }

  @override
  String toString() {
    return 'CityInfo(name: $name, population: $population, monuments: ${monuments.length})';
  }
}

/// Modèle pour un monument ou lieu célèbre
/// 
/// ✨ AMÉLIORÉ pour inclure les données Wikipedia
class Monument {
  final String name;
  final String? description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  Monument({
    required this.name,
    this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  factory Monument.fromJson(Map<String, dynamic> json) {
    return Monument(
      name: json['name'] ?? 'Monument inconnu',
      description: json['description'],
      imageUrl: json['imageUrl'] ?? json['image'],  // Support des deux formats
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'Monument(name: $name)';
  }
}
