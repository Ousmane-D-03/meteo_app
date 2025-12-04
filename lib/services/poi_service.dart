import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meteo_app/services/geocoding_service.dart';

class PoiService {
  static Future<Map<String, dynamic>> fetchPoiDataForCity(String city) async {
    final location = await GeocodingService.forwardGeocode(city);
    final double lat = location[0];
    final double lon = location[1];
    final double lat1 = lat - 0.01;
    final double lon1 = lon - 0.01;
    final double lat2 = lat + 0.01;
    final double lon2 = lon + 0.01;

    final query = '''
      [out:json];
      (
        node["leisure"="park"]($lat1,$lon1,$lat2,$lon2);
        node["amenity"="restaurant"]($lat1,$lon1,$lat2,$lon2);
        node["tourism"="museum"]($lat1,$lon1,$lat2,$lon2);
        node["railway"="station"]($lat1,$lon1,$lat2,$lon2);
        node["amenity"="university"]($lat1,$lon1,$lat2,$lon2);
      );
      out;
      ''';

    final url = Uri.parse(
      "https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}",
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de la récupération des données POI');
    }
  }

  static Map<String, List<Map<String, dynamic>>> filterPoiData(Map<String, dynamic> poiData) {
    Map<String, List<Map<String, dynamic>>> categorizedPOIs = {
      'Parcs': [],
      'Restaurants': [],
      'Musées': [],
      'Gares': [],
      'Universités': [],
    };

    for (var element in poiData['elements']) {
      String? name = element['tags'] != null ? element['tags']['name'] : 'Inconnu';
      double lat = element['lat'];
      double lon = element['lon'];
      Map<String, dynamic> poiInfo = {
        'name': name,
        'latitude': lat,
        'longitude': lon,
      };

      if (element['tags'] != null) {
        if (element['tags']['leisure'] == 'park') {
          categorizedPOIs['Parcs']!.add(poiInfo);
        } else if (element['tags']['amenity'] == 'restaurant') {
          categorizedPOIs['Restaurants']!.add(poiInfo);
        } else if (element['tags']['tourism'] == 'museum') {
          categorizedPOIs['Musées']!.add(poiInfo);
        } else if (element['tags']['railway'] == 'station') {
          categorizedPOIs['Gares']!.add(poiInfo);
        } else if (element['tags']['amenity'] == 'university') {
          categorizedPOIs['Universités']!.add(poiInfo);
        }
      }
    }

    return categorizedPOIs;
  }
}
