import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/delivery_model.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Live delivery route map
//
// Shows the volunteer's live GPS location, the donor (pickup) and drop-off
// points, and a road route the volunteer can follow:
//   • ACCEPTED               → route from the volunteer to the donor
//   • PICKED_UP / IN_TRANSIT → route from the volunteer to the drop-off
//
// Road routes come from the public OSRM server (no API key). If it cannot be
// reached, a straight dashed line is drawn instead.
// ─────────────────────────────────────────────────────────────────────────────

const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

// Statuses where the volunteer is actively travelling.
const Set<String> _activeStatuses = {'ACCEPTED', 'PICKED_UP', 'IN_TRANSIT'};

// Fetch a new route after moving this far from where the last one started,
// but not more often than [_minRerouteInterval].
const double _rerouteDistanceMeters = 100;
const Duration _minRerouteInterval = Duration(seconds: 20);

class DeliveryRouteMap extends StatefulWidget {
  final VolunteerDelivery delivery;

  /// Map height. Ignored when [expand] is true.
  final double height;

  /// Fill the available space (used by the full-screen view).
  final bool expand;

  /// Called when the full-screen button is tapped. Hidden when null.
  final VoidCallback? onOpenFullScreen;

  const DeliveryRouteMap({
    super.key,
    required this.delivery,
    this.height = 360,
    this.expand = false,
    this.onOpenFullScreen,
  });

  @override
  State<DeliveryRouteMap> createState() => _DeliveryRouteMapState();
}

class _DeliveryRouteMapState extends State<DeliveryRouteMap> {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSub;
  LatLng? _myLocation;
  double? _myAccuracy;
  String? _locationError;

  List<LatLng> _routePoints = [];
  bool _routeIsFallback = false;
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  bool _loadingRoute = false;
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteAt;

  // When true the camera keeps the volunteer in view as they move.
  bool _followMe = false;
  bool _mapReady = false;

  VolunteerDelivery get _delivery => widget.delivery;

  bool get _isActive => _activeStatuses.contains(_delivery.status);

  bool get _headingToDonor => _delivery.status == 'ACCEPTED';

  LatLng? get _pickup => _validPoint(
        _delivery.pickupLatitude,
        _delivery.pickupLongitude,
      );

  LatLng? get _dropoff => _validPoint(
        _delivery.dropoffLatitude,
        _delivery.dropoffLongitude,
      );

  /// Where the volunteer should drive to next.
  LatLng? get _destination => _headingToDonor ? _pickup : _dropoff;

  String get _destinationName => _headingToDonor ? 'donor' : 'drop-off';

  static LatLng? _validPoint(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void didUpdateWidget(DeliveryRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Status changed (e.g. picked up) → the destination may have changed.
    if (oldWidget.delivery.status != _delivery.status) {
      _lastRouteOrigin = null;
      _routePoints = [];
      _updateRoute(force: true);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  // ===================== LIVE LOCATION =====================

  Future<void> _startLocationUpdates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on location (GPS) to see your live position.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Allow location access to see your live position.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location access is blocked. Enable it for this app in your '
          'phone settings.',
        );
      }

      if (!mounted) return;
      setState(() => _locationError = null);

      _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Only report a new position after moving 5 metres.
          distanceFilter: 5,
        ),
      ).listen(
        _onPosition,
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _locationError = 'Could not read your location. Tap retry.';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onPosition(Position position) {
    if (!mounted) return;

    final location = LatLng(position.latitude, position.longitude);
    final isFirstFix = _myLocation == null;

    setState(() {
      _myLocation = location;
      _myAccuracy = position.accuracy;
      _locationError = null;
    });

    if (_mapReady) {
      if (_followMe) {
        _mapController.move(location, _mapController.camera.zoom);
      } else if (isFirstFix) {
        _fitAll();
      }
    }

    _updateRoute();
  }

  // ===================== ROUTE =====================

  Future<void> _updateRoute({bool force = false}) async {
    final origin = _myLocation;
    final destination = _destination;

    if (!_isActive || origin == null || destination == null) return;
    if (_loadingRoute) return;

    if (!force && _lastRouteOrigin != null) {
      final moved = const Distance().as(
        LengthUnit.Meter,
        _lastRouteOrigin!,
        origin,
      );
      final recent = _lastRouteAt != null &&
          DateTime.now().difference(_lastRouteAt!) < _minRerouteInterval;

      if (moved < _rerouteDistanceMeters || recent) return;
    }

    _loadingRoute = true;
    _lastRouteOrigin = origin;
    _lastRouteAt = DateTime.now();

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('Routing failed (HTTP ${response.statusCode})');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List?;

      if (body['code'] != 'Ok' || routes == null || routes.isEmpty) {
        throw Exception('No road route found');
      }

      final route = routes.first as Map<String, dynamic>;
      final coordinates =
          (route['geometry'] as Map<String, dynamic>)['coordinates'] as List;

      final points = coordinates
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      if (!mounted) return;

      setState(() {
        _routePoints = points;
        _routeIsFallback = false;
        _routeDistanceMeters = (route['distance'] as num?)?.toDouble();
        _routeDurationSeconds = (route['duration'] as num?)?.toDouble();
      });
    } catch (_) {
      if (!mounted) return;

      // No road route available: show a straight line so the volunteer
      // still sees the direction and distance.
      setState(() {
        _routePoints = [origin, destination];
        _routeIsFallback = true;
        _routeDistanceMeters = const Distance().as(
          LengthUnit.Meter,
          origin,
          destination,
        );
        _routeDurationSeconds = null;
      });
    } finally {
      _loadingRoute = false;
    }
  }

  // ===================== CAMERA =====================

  /// Points the "show whole route" camera fits: the volunteer and where
  /// they are heading, or both stops when there is no destination yet.
  List<LatLng> get _visiblePoints {
    final destination = _destination;

    return [
      ?_myLocation,
      if (destination != null) destination else ...[?_pickup, ?_dropoff],
    ];
  }

  void _fitAll() {
    final points = _visiblePoints;
    if (!_mapReady || points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(50, 90, 50, 60),
        maxZoom: 16,
      ),
    );
  }

  void _toggleFollowMe() {
    setState(() => _followMe = !_followMe);

    if (_followMe && _myLocation != null) {
      _mapController.move(_myLocation!, 16);
    } else if (!_followMe) {
      _fitAll();
    }
  }

  // ===================== UI =====================

  String _formatDistance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '${minutes < 1 ? 1 : minutes} min';
    return '${minutes ~/ 60} h ${minutes % 60} min';
  }

  Widget _labelledMarker(IconData icon, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 34),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 3),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _myLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return Material(
      elevation: 3,
      color: active ? Colors.blue : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: active ? Colors.white : Colors.blue),
      ),
    );
  }

  /// Banner at the top of the map: distance/time to the next stop, or why
  /// a route cannot be shown.
  Widget? _infoBanner() {
    String? text;
    IconData icon = Icons.info_outline;
    Color color = AppTheme.darkText;

    if (_locationError != null) {
      text = _locationError;
      icon = Icons.location_off_outlined;
      color = Colors.red.shade700;
    } else if (!_isActive) {
      return null;
    } else if (_destination == null) {
      text = _headingToDonor
          ? 'The donor location is not available for this delivery.'
          : 'The drop-off location is not available for this delivery.';
      icon = Icons.wrong_location_outlined;
      color = Colors.orange.shade800;
    } else if (_myLocation == null) {
      text = 'Finding your location...';
      icon = Icons.gps_not_fixed;
    } else if (_routeDistanceMeters != null) {
      final parts = [
        'To $_destinationName: ${_formatDistance(_routeDistanceMeters!)}',
        if (_routeDurationSeconds != null)
          _formatDuration(_routeDurationSeconds!),
      ];
      text = parts.join(' · ');
      if (_routeIsFallback) text = '$text (straight line)';
      icon = Icons.navigation_outlined;
      color = AppTheme.primaryGreenDark;
    } else {
      text = 'Finding the best route...';
      icon = Icons.route_outlined;
    }

    return Material(
      elevation: 3,
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (_locationError != null)
              TextButton(
                onPressed: _startLocationUpdates,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickup;
    final dropoff = _dropoff;
    final initialPoints = [?pickup, ?dropoff];
    final banner = _infoBanner();

    final map = Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                initialPoints.isEmpty ? _sriLankaCenter : initialPoints.first,
            initialZoom: initialPoints.isEmpty ? 7 : 14,
            initialCameraFit: initialPoints.length > 1
                ? CameraFit.coordinates(
                    coordinates: initialPoints,
                    padding: const EdgeInsets.fromLTRB(50, 90, 50, 60),
                    maxZoom: 15,
                  )
                : null,
            onMapReady: () {
              _mapReady = true;
              if (_myLocation != null) _fitAll();
            },
            // Moving the map by hand stops follow mode.
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _followMe) {
                setState(() => _followMe = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.foodlink.app',
            ),

            // Route to follow (active deliveries).
            if (_isActive && _routePoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 6,
                    color: const Color(0xFF1A73E8),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                    pattern: _routeIsFallback
                        ? StrokePattern.dashed(segments: const [12, 8])
                        : const StrokePattern.solid(),
                  ),
                ],
              ),

            if (_myLocation != null && _myAccuracy != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _myLocation!,
                    radius: _myAccuracy!,
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderColor: Colors.blue.withValues(alpha: 0.3),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (pickup != null)
                  Marker(
                    point: pickup,
                    width: 90,
                    height: 62,
                    alignment: Alignment.topCenter,
                    child: _labelledMarker(
                      Icons.store,
                      AppTheme.primaryGreenDark,
                      'Donor',
                    ),
                  ),
                if (dropoff != null)
                  Marker(
                    point: dropoff,
                    width: 90,
                    height: 62,
                    alignment: Alignment.topCenter,
                    child: _labelledMarker(
                      Icons.location_on,
                      Colors.red,
                      'Drop-off',
                    ),
                  ),
                if (_myLocation != null)
                  Marker(
                    point: _myLocation!,
                    width: 44,
                    height: 44,
                    child: _myLocationMarker(),
                  ),
              ],
            ),

            const SimpleAttributionWidget(
              source: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),

        if (banner != null)
          Positioned(top: 12, left: 12, right: 12, child: banner),

        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            children: [
              if (widget.onOpenFullScreen != null) ...[
                _mapButton(
                  icon: Icons.fullscreen,
                  tooltip: 'Full screen',
                  onPressed: widget.onOpenFullScreen!,
                ),
                const SizedBox(height: 10),
              ],
              _mapButton(
                icon: Icons.zoom_out_map,
                tooltip: 'Show whole route',
                onPressed: () {
                  setState(() => _followMe = false);
                  _fitAll();
                },
              ),
              const SizedBox(height: 10),
              _mapButton(
                icon: _followMe ? Icons.navigation : Icons.my_location,
                tooltip: _followMe ? 'Stop following me' : 'Follow me',
                active: _followMe,
                onPressed: _myLocation == null
                    ? _startLocationUpdates
                    : _toggleFollowMe,
              ),
            ],
          ),
        ),
      ],
    );

    return widget.expand ? map : SizedBox(height: widget.height, child: map);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen navigation view
// ─────────────────────────────────────────────────────────────────────────────

class DeliveryNavigationScreen extends StatelessWidget {
  final VolunteerDelivery delivery;

  const DeliveryNavigationScreen({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final headingToDonor = delivery.status == 'ACCEPTED';

    return Scaffold(
      appBar: AppBar(
        title: Text(headingToDonor ? 'Route to Donor' : 'Route to Drop-off'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: DeliveryRouteMap(delivery: delivery, expand: true),
    );
  }
}
