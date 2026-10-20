import 'package:dio/dio.dart';
import '../auth/oidc_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.auth);

  final EventlyAuth auth;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Do not overwrite an explicitly supplied Authorization header.
      if (!options.headers.containsKey('Authorization')) {
        final token = await auth.getAccessToken();

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }

      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}