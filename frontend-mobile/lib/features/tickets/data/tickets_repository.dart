
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/auth/oidc_service.dart';
import '../../../core/network/api_client.dart';
import 'ticket_models.dart';

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  return TicketsRepository(ref);
});

final myTicketsProvider = FutureProvider<TicketPage>((ref) {
  return ref.watch(ticketsRepositoryProvider).getMyTickets();
});

class TicketsRepository {
  TicketsRepository(this.ref);

  final Ref ref;

  Future<TicketPage> getMyTickets() async {
    final auth = EventlyAuth.instance;
    await auth.initialize();

    final token = await auth.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'No access token available. Please sign in again.',
      );
    }

    try {
      final response = await ref.read(dioProvider).get(
        '/api/v1/tickets',
        queryParameters: {
          'page': 0,
          'size': 20,
          'sort': 'id,desc',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('MY TICKETS: status = ${response.statusCode}');

      return TicketPage.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      debugPrint('MY TICKETS: URL = ${e.requestOptions.uri}');
      debugPrint('MY TICKETS: status = ${e.response?.statusCode}');
      debugPrint('MY TICKETS: response = ${e.response?.data}');
      rethrow;
    }
  }
}
