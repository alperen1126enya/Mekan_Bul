import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/mekan.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if location permission is granted
  Future<bool> checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Calculate distance between two points in kilometers using Haversine formula
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Get nearby mekanlar within specified radius
  List<Mekan> getNearbyMekanlar(
    List<Mekan> allMekanlar,
    Position currentPosition,
    double radiusKm,
  ) {
    final nearbyMekanlar = <Mekan>[];
    
    for (final mekan in allMekanlar) {
      if (mekan.latitude != null && mekan.longitude != null) {
        final distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          mekan.latitude!,
          mekan.longitude!,
        );
        
        if (distance <= radiusKm) {
          nearbyMekanlar.add(mekan);
        }
      }
    }
    
    // Sort by distance (closest first)
    nearbyMekanlar.sort((a, b) {
      final distA = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        a.latitude!,
        a.longitude!,
      );
      final distB = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        b.latitude!,
        b.longitude!,
      );
      return distA.compareTo(distB);
    });
    
    return nearbyMekanlar;
  }

  /// Get distance string (formatted for display)
  String getDistanceString(Position currentPosition, Mekan mekan) {
    if (mekan.latitude == null || mekan.longitude == null) {
      return 'Bilinmiyor';
    }
    
    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      mekan.latitude!,
      mekan.longitude!,
    );
    
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }
}
