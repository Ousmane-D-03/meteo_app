import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meteo_app/database/providers/cache_provider.dart';
import 'package:meteo_app/services/geolocation_service.dart';
import 'package:meteo_app/services/geocoding_service.dart';
import 'package:meteo_app/services/weather_service.dart';
import 'package:meteo_app/services/poi_service.dart';
import 'package:meteo_app/database/providers/favori_provider.dart';
import 'package:meteo_app/database/models/favori.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final TextEditingController _cityController = TextEditingController();
  final MapController _mapController = MapController();
  FavoriteProvider favoriteProvider = FavoriteProvider();
  List<Favorite> allPlaces = [];

  //bool isFavoritePlace = false;

  LatLng _center = const LatLng(48.8566, 2.3522);

  String _cityName = '';
  String _latitude = '';
  String _longitude = '';

  List<Map<String, dynamic>> categories = [
    {'name': 'Parcs', 'selected': false},
    {'name': 'Restaurants', 'selected': false},
    {'name': 'Musées', 'selected': false},
    {'name': 'Gares', 'selected': false},
    {'name': 'Universités', 'selected': false},
  ];

  List<Map<String, dynamic>> selectedPoi = [];

  List<Map<String, dynamic>> favoritePlaces = [
    {
      'name': 'Tour Eiffel',
      'gradient': [Color(0xFF6B8DD6), Color(0xFF8E78C6)],
      'icon': Icons.tour,
    },
    {
      'name': 'Musée du Louvre',
      'gradient': [Color(0xFFFFA726), Color(0xFFFF7043)],
      'icon': Icons.museum,
    },
    {
      'name': 'Sacré-Cœur',
      'gradient': [Color(0xFFEF5350), Color(0xFFE91E63)],
      'icon': Icons.church,
    },
  ];

  Future<void> _loadFavorites() async {
    allPlaces = await favoriteProvider.getAllFavorites();
    setState(() {}); // rafraîchit l'UI
  }

  @override
  void initState() {
    super.initState();
    _initDb().then((_) => _loadFavorites());
    _getCurrentLocation();
  }

  Future<void> _initDb() async {
    await favoriteProvider.open();
  }

  Future<void> _savePoiToDatabase(List<Map<String, dynamic>> pois, String city) async {
    for (var poi in pois) {
      // Vérifie si le POI existe déjà
      bool exists = allPlaces.any((f) => f.name == poi['name']);
      if (!exists) {
        Favorite newFav = Favorite(
          name: poi['name'],
          latitude: poi['latitude'],
          longitude: poi['longitude'],
          city: city,
          category: poi['category'] ?? 'Autre',
          isFavorite: false,
        );
        await favoriteProvider.insert(newFav);
        allPlaces.add(newFav); // Ajoute à la liste mémoire
      }
    }
  }

  //j'ai l Erreur lors de la récupération de la localisation : MissingPluginException(No implementation found for method getCurrentPosition on channel
  //flutter.baseflow.com/geolocator)

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await GeolocationService.getCurrentPosition();
      final city = await GeocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
        _cityName = city;
        _cityController.text = city;
        getWeatherData().then((data) => _updateWeatherData(data));
      });
      _mapController.move(_center, 12.0);
    } catch (e) {
      print("Erreur lors de la récupération de la localisation : $e");
    }
  }

  Future<String> _getCityName(double lat, double lon) async {
    return await GeocodingService.reverseGeocode(lat, lon);
  }

  Future<List<dynamic>> _getCoordinates(String city) async {
    return await GeocodingService.forwardGeocode(city);
  }

  Future<Map<String, dynamic>> getWeatherData() async {
    List<dynamic> location = await _getCoordinates(_cityController.text);
    return await WeatherService.fetchWeatherDataByCoords(
      location[0],
      location[1],
    );
  }

  Map<String, dynamic> weatherData = {
    'temp': '--',
    'condition': '--',
    'minMax': '--/--',
    'humidity': '--%',
    'wind': '-- km/h ',
  };

  String decodeWeatherCode(int code) {
    switch (code) {
      case 0:
        return "Ciel dégagé";
      case 1:
        return "Peu nuageux";
      case 2:
        return "Partiellement nuageux";
      case 3:
        return "Nuageux";
      case 45:
        return "Brouillard";
      case 48:
        return "Brouillard givrant";
      case 51:
        return "Bruine légère";
      case 53:
        return "Bruine modérée";
      case 55:
        return "Bruine dense";
      case 61:
        return "Pluie légère";
      case 63:
        return "Pluie modérée";
      case 65:
        return "Pluie forte";
      case 66:
        return "Pluie verglaçante légère";
      case 67:
        return "Pluie verglaçante forte";
      case 71:
        return "Neige faible";
      case 73:
        return "Neige modérée";
      case 75:
        return "Neige forte";
      case 77:
        return "Grésil";
      case 80:
        return "Averses légères";
      case 81:
        return "Averses modérées";
      case 82:
        return "Averses fortes";
      case 85:
        return "Neige légère";
      case 86:
        return "Neige forte";
      case 95:
        return "Orage";
      case 96:
        return "Orage avec grêle légère";
      case 99:
        return "Orage avec grêle forte";
      default:
        return "Inconnu";
    }
  }

  void _updateWeatherData(Map<String, dynamic> data) {
    setState(() {
      weatherData = {
        'temp': data['current_weather']['temperature'].toString(),
        'condition': decodeWeatherCode(data['current_weather']['weathercode']),
        'minMax':
            '${data['daily']['temperature_2m_min'][0]}/${data['daily']['temperature_2m_max'][0]}',
        'humidity': '${data['hourly']['relative_humidity_2m'][0]}%',
        'wind': '${data['current_weather']['windspeed']} km/h',
      };
    });
  }

  Future<Map<String, dynamic>> getPoiData() async {
    return await PoiService.fetchPoiDataForCity(_cityController.text);
  }

  // Filtrage des POI par catégorie avec leur coordonnée comprise
  Map<String, List<Map<String, dynamic>>> poiDataFilter(
    Map<String, dynamic> poiData,
  ) {
    return PoiService.filterPoiData(poiData);
  }

  void _updatePoiData(Map<String, List<Map<String, dynamic>>> categorizedPOIs) {
    // Mettre à jour l'interface utilisateur avec les POI filtrés
    // Par exemple, afficher les POI sur la carte
    setState(() {
      // Mettre à jour l'état avec les POI filtrés en prenant entre 4 et le min par catégorie
      selectedPoi = [];
      for (var category in categories) {
        if (category['selected']) {
          String catName = category['name'];
          List<Map<String, dynamic>> pois = categorizedPOIs[catName] ?? [];
          selectedPoi.addAll(
            pois.take(4),
          ); // Prendre jusqu'à 4 POI par catégorie
        }
      }
    });
    _savePoiToDatabase(selectedPoi, _cityName);
  }

  Future<void> _searchCity() async {
    try {
      if (_cityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un nom de ville valide.'),
          ),
        );
        return;
      }

      List<dynamic> location = await _getCoordinates(_cityController.text);
      if (location.isNotEmpty) {
        setState(() {
          _center = LatLng(location[0], location[1]);
          _latitude = location[0].toString();
          _longitude = location[1].toString();
          _cityName = _cityController.text;
        });
        _mapController.move(_center, 12.0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune position trouvée pour cette ville.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du géocodage : ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une ville...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onEditingComplete: () async {
                    Map<String, dynamic> data = await getWeatherData();
                    _updateWeatherData(data);
                  },
                  onSubmitted: (value) => _searchCity(),
                ),
              ),

              // Nom de la ville
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _cityName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Carte météo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny,
                            color: Colors.orange[400],
                            size: 50,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${weatherData['temp']}°',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWeatherInfo('Météo', weatherData['condition']),
                          _buildWeatherInfo('Min/Max', weatherData['minMax']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWeatherInfo(
                            'Humidité',
                            weatherData['humidity'],
                          ),
                          _buildWeatherInfo('Vent', weatherData['wind']),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Catégories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              for (var cat in categories) {
                                cat['selected'] = false;
                              }
                              getPoiData().then(
                                (poiData) =>
                                    _updatePoiData(poiDataFilter(poiData)),
                              );
                              categories[index]['selected'] = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  category['selected']
                                      ? Colors.blue
                                      : Colors.grey[300],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              category['name'],
                              style: TextStyle(
                                color:
                                    category['selected']
                                        ? Colors.white
                                        : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Lieux trouvés",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    for (var poi in selectedPoi)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              poi['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            // Icône favori par POI
                            IconButton(
                              onPressed: () async {
                                // Cherche si le POI existe déjà dans allPlaces
                                Favorite? fav = allPlaces.firstWhere(
                                  (f) => f.name == poi['name'],
                                  orElse:
                                      () => Favorite(
                                        name: poi['name'],
                                        latitude: poi['latitude'],
                                        longitude: poi['longitude'],
                                        city: _cityName,
                                        category: poi['category'] ?? 'Autre',
                                        isFavorite: false,
                                      ),
                                );

                                // Toggle isFavorite
                                fav.isFavorite = !fav.isFavorite;

                                // Sauvegarde en base
                                if (fav.id != null) {
                                  await favoriteProvider.toggleFavorite(fav);
                                } else {
                                  await favoriteProvider.insert(fav);
                                  allPlaces.add(
                                    fav,
                                  ); // ajoute à la liste mémoire
                                }

                                setState(() {}); // rafraîchit l'UI
                              },
                              icon: Icon(
                                // Utilise la liste locale pour déterminer l'état
                                allPlaces.any(
                                      (f) =>
                                          f.name == poi['name'] && f.isFavorite,
                                    )
                                    ? Icons.star
                                    : Icons.star_border,
                                color:
                                    allPlaces.any(
                                          (f) =>
                                              f.name == poi['name'] &&
                                              f.isFavorite,
                                        )
                                        ? Colors.amber
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Carte
              Container(
                height: 300,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _center,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),

                        // Marqueurs pour les POI sélectionnés
                        for (var poi in selectedPoi)
                          Marker(
                            point: LatLng(poi['latitude'], poi['longitude']),
                            child: const Icon(
                              Icons.place,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Mes Lieux Favoris
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Mes Lieux Favoris',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              // Liste des lieux favoris
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: favoritePlaces.length,
                  itemBuilder: (context, index) {
                    final place = favoritePlaces[index];
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: place['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: place['gradient'][0].withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Text(
                              place['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Center(
                            child: Icon(
                              place['icon'],
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _searchCity,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  Widget _buildWeatherInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

//Placecard
Widget placeCard(
  String placeName,
  String cityName,
  bool isFavoritePlace, {
  required VoidCallback onFavoriteToggle,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Icon(Icons.place, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(placeName, style: const TextStyle(fontSize: 18)),
          ),
          IconButton(
            icon: Icon(
              isFavoritePlace ? Icons.favorite : Icons.favorite_border,
              color: isFavoritePlace ? Colors.red : Colors.grey,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
    ),
  );
}
