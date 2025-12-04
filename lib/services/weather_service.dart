import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static Future<Map<String, dynamic>> fetchWeatherDataByCoords(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current_weather=true'
        '&hourly=temperature_2m,relative_humidity_2m,precipitation,windspeed_10m'
        '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum'
        '&timezone=auto');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de la récupération des données météo');
    }
  }
}
