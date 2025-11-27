import 'package:geolocator/geolocator.dart';

class GeolocationService {
  static Future<Position> getCurrentPosition({LocationAccuracy accuracy = LocationAccuracy.high}) async {
    return await Geolocator.getCurrentPosition(desiredAccuracy: accuracy);
  }
}
