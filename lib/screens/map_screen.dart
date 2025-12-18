import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/mekan.dart';
import '../providers/auth_provider.dart';
import '../providers/mekan_provider.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  Set<Marker> _markers = {};

  // İstanbul center as default
  static const LatLng _istanbulCenter = LatLng(41.0082, 28.9784);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadMekanlar();
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _locationService.checkLocationPermission();
    setState(() => _hasLocationPermission = hasPermission);

    if (hasPermission) {
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        if (position != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              14,
            ),
          );
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    final granted = await _locationService.requestLocationPermission();
    if (granted) {
      await _initializeLocation();
    }
  }

  void _loadMekanlar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mekanProvider = context.read<MekanProvider>();
      if (mekanProvider.mekanlar.isEmpty) {
        mekanProvider.loadAllMekanlar();
      }
    });
  }

  void _buildMarkers(List<Mekan> mekanlar) {
    final markers = <Marker>{};

    for (final mekan in mekanlar) {
      if (mekan.latitude != null && mekan.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('mekan_${mekan.id}'),
            position: LatLng(mekan.latitude!, mekan.longitude!),
            infoWindow: InfoWindow(
              title: mekan.name,
              snippet: '${mekan.categoryDisplayName} • ⭐ ${mekan.rating.toStringAsFixed(1)}',
              onTap: () => _onMarkerTapped(mekan),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getCategoryHue(mekan.category),
            ),
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  double _getCategoryHue(String category) {
    switch (category.toLowerCase()) {
      case 'restoran':
        return BitmapDescriptor.hueRed;
      case 'cafe':
        return BitmapDescriptor.hueOrange;
      case 'eglence':
        return BitmapDescriptor.hueMagenta;
      case 'fast_food':
        return BitmapDescriptor.hueYellow;
      case 'bar':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  void _onMarkerTapped(Mekan mekan) {
    final authProvider = context.read<AuthProvider>();
    context.read<MekanProvider>().selectMekan(
          mekan.id!,
          userId: authProvider.currentUser?.id,
        );
    Navigator.pushNamed(context, AppConstants.mekanDetailRoute);
  }

  @override
  Widget build(BuildContext context) {
    final mekanProvider = context.watch<MekanProvider>();

    // Build markers when mekanlar changes
    if (mekanProvider.mekanlar.isNotEmpty && _markers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildMarkers(mekanProvider.mekanlar);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _istanbulCenter,
              zoom: 12,
            ),
            style: _darkMapStyle,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Harita',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${_markers.length} mekan',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Category legend
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.categories.map((cat) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat['emoji'] as String),
                              const SizedBox(width: 6),
                              Text(
                                cat['name'] as String,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Permission request overlay
          if (!_hasLocationPermission && !_isLoading)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.location_off_rounded, color: AppColors.warning, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Konum izni verilmedi',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Yakınındaki mekanları görebilmek için konum izni ver.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _requestLocationPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İzin Ver', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          // My location button
          if (_hasLocationPermission)
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'my_location',
                backgroundColor: AppColors.surface,
                onPressed: () async {
                  final position = await _locationService.getCurrentLocation();
                  if (position != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(position.latitude, position.longitude),
                        15,
                      ),
                    );
                    setState(() => _currentPosition = position);
                  }
                },
                child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  // Dark map style
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#64779e"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
  {"featureType": "poi", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#3C7680"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "road", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#b0d5ce"}]},
  {"featureType": "road.highway", "elementType": "labels.text.stroke", "stylers": [{"color": "#023e58"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "transit", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "transit.line", "elementType": "geometry.fill", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#3a4762"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
]
''';
}
