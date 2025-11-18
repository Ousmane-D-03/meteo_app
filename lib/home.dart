import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';




class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final TextEditingController _cityController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _center =
      const LatLng(48.8566, 2.3522); // Coordonnées par défaut : Paris
  String _latitude = '48.8566';
  String _longitude = '2.3522';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Obtenir la position actuelle de l'utilisateur
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activer le service de localisation')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de localisation refusée')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation bloquée')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
      _mapController.move(_center, 12.0); // Centrer la carte
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de l\'obtention de la localisation')),
      );
    }
  }

  // Récupérer les coordonnées d'une ville (un couple [lat, long])
  Future<List<double>> _getCoordinates(String city) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$city&format=json&limit=1');
    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return [lat, lon];
      }
    }
    throw Exception("Aucune coordonnée trouvée pour $city");
  }

  // Rechercher une ville et centrer la carte
  Future<void> _searchCity() async {
    try {
      if (_cityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez entrer un nom de ville valide.')),
        );
        return;
      }

      List<double> location = await _getCoordinates(_cityController.text);
      if (location.isNotEmpty) {
        setState(() {
          _center = LatLng(location[0], location[1]);
          _latitude = location[0].toString();
          _longitude = location[1].toString();
        });
        _mapController.move(_center, 12.0); // Centrer la carte
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aucune position trouvée pour cette ville.')),
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
      appBar: AppBar(
        title: const Text('OpenStreetMap Search'),
      ),
      body: Column(
        children: [
          Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Rechercher le nom du lieu', 
            hintText: 'Ex: Paris',
            prefixIcon: const Icon(Icons.search), 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          onSubmitted: (value) {
            _searchCity();
          },
        ),
      ),
          Text('Latitude : $_latitude', style: const TextStyle(fontSize: 16)),
          Text('Longitude : $_longitude', style: const TextStyle(fontSize: 16)),
          Expanded(
            child: FlutterMap(
              mapController: _mapController, // Ajout du contrôleur
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                  subdomains: const ['a', 'b', 'c', 'd'],
                  // attributionBuilder: (_) {
                  //   return Text("© OpenStreetMap contributors | © Carto");
                  // },
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _searchCity,
        child: const Icon(Icons.search),
      ),
    );
  }
}