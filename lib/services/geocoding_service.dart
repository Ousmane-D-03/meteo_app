import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static Future<String> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');
    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['address']?['city'] ?? data['address']?['town'] ?? data['address']?['village'] ?? 'Ville inconnue';
    } else {
      throw Exception('Erreur lors de la récupération du nom de la ville');
    }
  }

  static Future<List<dynamic>> forwardGeocode(String city) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$city&format=json&limit=1');
    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        final displayName = data[0]['display_name'] ?? city;
        return [lat, lon, displayName];
      }
    }
    throw Exception('Aucune coordonnée trouvée pour $city');
  }
}
