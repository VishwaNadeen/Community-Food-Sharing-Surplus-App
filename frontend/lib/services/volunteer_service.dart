import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/delivery_model.dart';
import '../models/volunteer_model.dart';
import 'auth_service.dart';

class VolunteerService {
  static String get _baseUrl =>
      '${AuthService.baseUrl}/volunteer';

  static Map<String, String> _headers(
    String token,
  ) =>
      {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static dynamic _decode(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(response.body);
  }

  static String _errorMessage(
    dynamic data,
    String fallback,
  ) {
    if (data is Map<String, dynamic>) {
      if (data['error'] != null) {
        return data['error'].toString();
      }

      if (data['errors'] is List) {
        return (data['errors'] as List)
            .join('\n');
      }
    }

    return fallback;
  }

  static void _ensureSuccess(
    http.Response response,
    dynamic data,
    String fallback,
  ) {
    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _errorMessage(
          data,
          fallback,
        ),
      );
    }
  }

  // -----------------------------------------------------
  // AVAILABILITY
  // -----------------------------------------------------

  static Future<VolunteerAvailability>
      getAvailability(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/availability',
      ),
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to load availability.',
    );

    return VolunteerAvailability.fromJson(
      Map<String, dynamic>.from(
        data['availability'] as Map,
      ),
    );
  }

  static Future<VolunteerAvailability>
      updateAvailability({
    required String token,
    required String status,
    String? notes,
  }) async {
    final response = await http.put(
      Uri.parse(
        '$_baseUrl/availability',
      ),
      headers: _headers(token),
      body: jsonEncode({
        'status': status,
        'notes': notes?.trim(),
      }),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to update availability.',
    );

    return VolunteerAvailability.fromJson(
      Map<String, dynamic>.from(
        data['availability'] as Map,
      ),
    );
  }

  // -----------------------------------------------------
  // VOLUNTEER PROFILE
  // -----------------------------------------------------

  static Future<VolunteerProfileModel> getProfile(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profile'),
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to load volunteer profile.',
    );

    return VolunteerProfileModel.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<VolunteerProfileModel> updateProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/profile'),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    final resData = _decode(response);

    _ensureSuccess(
      response,
      resData,
      'Failed to update volunteer profile.',
    );

    return VolunteerProfileModel.fromJson(
      Map<String, dynamic>.from(resData as Map),
    );
  }

  // -----------------------------------------------------
  // DASHBOARD
  // -----------------------------------------------------

  static Future<VolunteerDashboardStats>
      getDashboard(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/dashboard',
      ),
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to load volunteer dashboard.',
    );

    return VolunteerDashboardStats.fromJson(
      Map<String, dynamic>.from(
        data['dashboard'] as Map,
      ),
    );
  }

  // -----------------------------------------------------
  // DELIVERIES
  // -----------------------------------------------------

  static Future<List<VolunteerDelivery>>
      getDeliveries({
    required String token,
    String? status,
    bool sortByExpiry = false,
  }) async {
    final query = <String, String>{};

    if (status != null &&
        status.isNotEmpty) {
      query['status'] = status;
    }

    if (sortByExpiry) {
      query['sortBy'] = 'expiry';
    }

    final uri =
        Uri.parse(
          '$_baseUrl/deliveries',
        ).replace(
          queryParameters:
              query.isEmpty ? null : query,
        );

    final response = await http.get(
      uri,
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to load deliveries.',
    );

    final list =
        data['deliveries']
                as List<dynamic>? ??
            [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(
          VolunteerDelivery.fromJson,
        )
        .toList();
  }

  static Future<VolunteerDelivery>
      getDelivery({
    required String token,
    required String deliveryId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/deliveries/$deliveryId',
      ),
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to load delivery.',
    );

    return VolunteerDelivery.fromJson(
      Map<String, dynamic>.from(
        data['delivery'] as Map,
      ),
    );
  }

  // -----------------------------------------------------
  // ACCEPT DELIVERY
  // -----------------------------------------------------

  static Future<VolunteerDelivery>
      acceptDelivery({
    required String token,
    required String deliveryId,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '$_baseUrl/deliveries/$deliveryId/accept',
      ),
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to accept delivery.',
    );

    return VolunteerDelivery.fromJson(
      Map<String, dynamic>.from(
        data['delivery'] as Map,
      ),
    );
  }

  // -----------------------------------------------------
  // REJECT DELIVERY
  // -----------------------------------------------------

  static Future<VolunteerDelivery>
      rejectDelivery({
    required String token,
    required String deliveryId,
    required String rejectionReason,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '$_baseUrl/deliveries/$deliveryId/reject',
      ),
      headers: _headers(token),
      body: jsonEncode({
        'rejectionReason':
            rejectionReason.trim(),
      }),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to reject delivery.',
    );

    return VolunteerDelivery.fromJson(
      Map<String, dynamic>.from(
        data['delivery'] as Map,
      ),
    );
  }

  // -----------------------------------------------------
  // UPDATE DELIVERY STATUS
  // -----------------------------------------------------

  static Future<VolunteerDelivery>
      updateDeliveryStatus({
    required String token,
    required String deliveryId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '$_baseUrl/deliveries/$deliveryId/status',
      ),
      headers: _headers(token),
      body: jsonEncode({
        'status': status,
      }),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to update delivery status.',
    );

    return VolunteerDelivery.fromJson(
      Map<String, dynamic>.from(
        data['delivery'] as Map,
      ),
    );
  }

  // -----------------------------------------------------
  // LOCATION
  // -----------------------------------------------------

  static Future<DeliveryTrackingEntry>
      updateLocation({
    required String token,
    required String deliveryId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/deliveries/$deliveryId/location',
      ),
      headers: _headers(token),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to update location.',
    );

    return DeliveryTrackingEntry.fromJson(
      Map<String, dynamic>.from(
        data['tracking'] as Map,
      ),
    );
  }

  // -----------------------------------------------------
  // TRACKING
  // -----------------------------------------------------

  static Future<List<DeliveryTrackingEntry>>
      getTracking({
    required String token,
    required String deliveryId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/deliveries/$deliveryId/tracking',
      ),
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to load tracking.',
    );

    final list =
        data['tracking'] as List<dynamic>? ??
            [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(
          DeliveryTrackingEntry.fromJson,
        )
        .toList();
  }

  // -----------------------------------------------------
  // REPORT PROBLEM
  // -----------------------------------------------------

  static Future<DeliveryProblem>
      reportProblem({
    required String token,
    required String deliveryId,
    required String problemType,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/deliveries/$deliveryId/problems',
      ),
      headers: _headers(token),
      body: jsonEncode({
        'problemType':
            problemType.trim(),
        'description':
            description.trim(),
      }),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to report problem.',
    );

    return DeliveryProblem.fromJson(
      Map<String, dynamic>.from(
        data['problem'] as Map,
      ),
    );
  }

  static Future<List<DeliveryProblem>>
      getProblems({
    required String token,
    required String deliveryId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/deliveries/$deliveryId/problems',
      ),
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to load delivery problems.',
    );

    final list =
        data['problems'] as List<dynamic>? ??
            [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(
          DeliveryProblem.fromJson,
        )
        .toList();
  }

  // -----------------------------------------------------
  // OPTIMIZED ROUTE
  // -----------------------------------------------------

  static Future<OptimizedVolunteerRoute>
      getOptimizedRoute(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/routes/optimized',
      ),
      headers: _headers(token),
    );

    final data = _decode(response);

    _ensureSuccess(
      response,
      data,
      'Failed to load optimized route.',
    );

    return OptimizedVolunteerRoute.fromJson(
      Map<String, dynamic>.from(
        data as Map,
      ),
    );
  }
}