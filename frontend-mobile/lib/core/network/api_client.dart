
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/oidc_service.dart';
import 'auth_interceptor.dart';

/// Override at runtime with --dart-define=API_BASE_URL=...
/// Chrome: http://localhost:8080
/// Android emulator: http://10.0.2.2:8080
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

final dioProvider = Provider<Dio>((ref) {
  final dio = _createDio();

  dio.interceptors.add(
    AuthInterceptor(EventlyAuth.instance),
  );

  ref.onDispose(dio.close);
  return dio;
});

Dio _createDio() {
  return Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );
}
