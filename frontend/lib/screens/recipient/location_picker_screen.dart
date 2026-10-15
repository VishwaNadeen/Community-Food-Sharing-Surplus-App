import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

// ====================== CONFIG ======================

class MapConfig {
  /// OpenStreetMap standard tiles (no API key). Fine for development and light
  /// production use; for heavy traffic switch to a tile provider of your own
  /// (MapTiler, Stadia, Mapbox...) by changing only this URL.
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// TODO: replace with your real application id (also used as the
  /// User-Agent for Nominatim, which OSM requires).
  static const userAgent = 'com.example.foodlink';

  static const defaultCenter = LatLng(6.9271, 79.8612); // Colombo
}

// ====================== MODELS ======================

class PickedLocation {
  final LatLng point;
  final String? label;
  final String? city;
  final String? district;

  const PickedLocation({
    required this.point,
    this.label,
    this.city,
    this.district,
  });
}

class GeoAddress {
  final String? label;
  final String? city;
  final String? district;

  const GeoAddress({this.label, this.city, this.district});
}

class PlaceResult {
  final String name;
  final LatLng point;

  const PlaceResult({required this.name, required this.point});
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

// ====================== SERVICES ======================

class LocationService {
  /// Gets the device's current position, handling services / permissions.
  static Future<LatLng> current() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        'Location services are turned off. Please enable GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. '
        'Enable it from your phone\'s app settings.',
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  }
}

class GeoService {
  static const _headers = {
    'User-Agent': MapConfig.userAgent,
    'Accept-Language': 'en',
  };

  /// Reverse geocoding through OpenStreetMap Nominatim.
  static Future<GeoAddress?> reverse(LatLng p) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '${p.latitude}',
        'lon': '${p.longitude}',
        'zoom': '16',
        'addressdetails': '1',
      });
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['error'] != null) return null;

      final addr =
          (data['address'] as Map?)?.cast<String, dynamic>() ?? const {};

      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = addr[k];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;
      }

      final district = pick(['state_district', 'county'])
          ?.replaceAll(RegExp(r'\s+District$', caseSensitive: false), '');
      final city = pick(['city', 'town', 'village', 'suburb', 'municipality']);

      final display = (data['display_name'] as String?) ?? '';
      final parts = display
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final label = parts.isEmpty ? null : parts.take(3).join(', ');

      return GeoAddress(label: label, city: city, district: district);
    } catch (_) {
      return null;
    }
  }

  /// Place search (Sri Lanka only) through Nominatim.
  static Future<List<PlaceResult>> search(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': query,
        'countrycodes': 'lk',
        'limit': '6',
      });
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];

      final list = jsonDecode(res.body) as List;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return PlaceResult(
          name: (m['display_name'] as String?) ?? 'Unknown place',
          point: LatLng(
            double.parse(m['lat'].toString()),
            double.parse(m['lon'].toString()),
          ),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Time zone for a coordinate (timeapi.io). Falls back to a Sri Lanka
  /// bounding box so it still works offline.
  static Future<String?> timeZoneFor(LatLng p) async {
    try {
      final uri = Uri.https('timeapi.io', '/api/timezone/coordinate', {
        'latitude': '${p.latitude}',
        'longitude': '${p.longitude}',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final tz = data['timeZone'];
        if (tz is String && tz.isNotEmpty) return tz;
      }
    } catch (_) {}

    if (p.latitude >= 5.7 &&
        p.latitude <= 10.0 &&
        p.longitude >= 79.4 &&
        p.longitude <= 82.0) {
      return 'Asia/Colombo';
    }
    return null;
  }
}

// ====================== SCREEN ======================

/// Full-screen map: the pin stays in the centre, the user moves the map.
/// Returns a [PickedLocation] when confirmed.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;

  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _searchCtl = TextEditingController();
  final _searchFocus = FocusNode();

  late LatLng _center;
  GeoAddress? _address;

  bool _moving = false;
  bool _resolving = false;
  bool _locating = false;
  bool _searching = false;

  List<PlaceResult> _results = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? MapConfig.defaultCenter;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAddress());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // -------------------- map events --------------------

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _center = camera.center;
    if (!_moving && mounted) setState(() => _moving = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _resolveAddress);
  }

  Future<void> _resolveAddress() async {
    if (!mounted) return;
    final point = _center;
    setState(() {
      _moving = false;
      _resolving = true;
    });

    final addr = await GeoService.reverse(point);
    if (!mounted || point != _center) return;

    setState(() {
      _address = addr;
      _resolving = false;
    });
  }

  // -------------------- actions --------------------

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final p = await LocationService.current();
      _map.move(p, 16);
    } on LocationException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not get your location. Please try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().length < 2) return;
    setState(() => _searching = true);
    final r = await GeoService.search(query.trim());
    if (!mounted) return;
    setState(() {
      _results = r;
      _searching = false;
    });
    if (r.isEmpty) _snack('No places found. Try a different search.');
  }

  void _selectResult(PlaceResult r) {
    _searchFocus.unfocus();
    setState(() => _results = []);
    _map.move(r.point, 16);
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedLocation(
        point: _center,
        label: _address?.label,
        city: _address?.city,
        district: _address?.district,
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
  }

  // -------------------- build --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15,
                    minZoom: 4,
                    maxZoom: 18,
                    onPositionChanged: _onPositionChanged,
                    onTap: (_, __) => _searchFocus.unfocus(),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapConfig.tileUrl,
                      userAgentPackageName: MapConfig.userAgent,
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),

                // centre pin (ignores touches so the map stays draggable)
                IgnorePointer(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(50),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 150),
                          padding:
                              EdgeInsets.only(bottom: _moving ? 80 : 48),
                          child: const Icon(
                            Icons.location_on,
                            size: 48,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // search + back
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Material(
                                color: Colors.white,
                                elevation: 3,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => Navigator.pop(context),
                                  child: const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 18,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _buildSearchField()),
                            ],
                          ),
                          if (_results.isNotEmpty) _buildResults(),
                        ],
                      ),
                    ),
                  ),
                ),

                // my location button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _goToMyLocation,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: _locating
                            ? const Padding(
                                padding: EdgeInsets.all(15),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primaryGreen,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: AppTheme.primaryGreenDark,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomCard(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: _searchCtl,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        onSubmitted: _runSearch,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search a place in Sri Lanka',
          hintStyle: const TextStyle(color: AppTheme.greyText, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.greyText, size: 22),
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                )
              : _searchCtl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _searchCtl.clear();
                        setState(() => _results = []);
                      },
                    )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _results.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (_, i) {
          final r = _results[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined,
                color: AppTheme.primaryGreenDark),
            title: Text(
              r.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5),
            ),
            onTap: () => _selectResult(r),
          );
        },
      ),
    );
  }

  Widget _buildBottomCard() {
    final label = _address?.label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      color: AppTheme.primaryGreenDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected location',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _moving
                            ? 'Move the map to place the pin...'
                            : (label ?? 'Pinned location'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_center.latitude.toStringAsFixed(5)}, '
                        '${_center.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_resolving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Confirm location',
              isLoading: false,
              onPressed: _moving ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}