
import 'package:dio/dio.dart';
import 'package:evently_mobile/core/auth/oidc_service.dart';

class OrganizerEventRepository {
  OrganizerEventRepository({Dio? dio})
      : _dio = dio ?? Dio(
          BaseOptions(
            // Android emulator: http://10.0.2.2:8080
            // Physical phone: use your laptop's LAN IP, e.g.
            // http://192.168.29.104:8080
            baseUrl:apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  final Dio _dio;

  // Set this to the backend URL accessible from your device.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  Future<Options> _authorizedOptions() async {
    final token = await EventlyAuth.instance.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please log in again. Access token is missing.');
    }

    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<List<Map<String, dynamic>>> listEvents({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '$apiBaseUrl/api/v1/events',
      queryParameters: {'page': page, 'size': size},
      options: await _authorizedOptions(),
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    final content = data['content'] as List? ?? [];

    return content
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getEvent(String eventId) async {
    final response = await _dio.get(
      '$apiBaseUrl/api/v1/events/$eventId',
      options: await _authorizedOptions(),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      '$apiBaseUrl/api/v1/events',
      data: body,
      options: await _authorizedOptions(),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateEvent(
    String eventId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put(
      '$apiBaseUrl/api/v1/events/$eventId',
      data: body,
      options: await _authorizedOptions(),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> deleteEvent(String eventId) async {
    await _dio.delete(
      '$apiBaseUrl/api/v1/events/$eventId',
      options: await _authorizedOptions(),
    );
  }
}
