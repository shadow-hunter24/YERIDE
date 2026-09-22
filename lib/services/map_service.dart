import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  static const String _apiKey = 'AIzaSyDc9A1jqYELRlpWW5p84S1drBBV09RjVdU';

  // Get route polyline points between two coordinates
  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: _apiKey,
      request: PolylineRequest(
        origin: PointLatLng(origin.latitude, origin.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
    );
    if (result.points.isNotEmpty) {
      return result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    }
    return [];
  }

  // Fit camera to show both markers
  static CameraUpdate fitBounds(LatLng point1, LatLng point2) {
    final southwest = LatLng(
      point1.latitude < point2.latitude ? point1.latitude : point2.latitude,
      point1.longitude < point2.longitude ? point1.longitude : point2.longitude,
    );
    final northeast = LatLng(
      point1.latitude > point2.latitude ? point1.latitude : point2.latitude,
      point1.longitude > point2.longitude ? point1.longitude : point2.longitude,
    );
    return CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: southwest, northeast: northeast),
      100,
    );
  }
}
