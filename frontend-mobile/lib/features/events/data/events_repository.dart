import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'event_models.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(dioProvider));
});

final publishedEventsProvider = FutureProvider.family<PublishedEventPage,
    ({String query, int page})>((ref, args) {
  return ref.watch(eventsRepositoryProvider).listPublishedEvents(
        query: args.query,
        page: args.page,
      );
});

final publishedEventDetailsProvider =
    FutureProvider.family<PublishedEventDetails, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).getPublishedEvent(eventId);
});

class EventsRepository {
  EventsRepository(this._dio);
  final Dio _dio;

  Future<PublishedEventPage> listPublishedEvents({
    String query = '',
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/published-events',
      queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        'page': page,
        'size': size,
      },
    );
    final data = response.data;
    if (data == null) throw const FormatException('Empty events response');
    return PublishedEventPage.fromJson(data);
  }

  Future<PublishedEventDetails> getPublishedEvent(String eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/published-events/$eventId',
    );
    final data = response.data;
    if (data == null) throw const FormatException('Empty event response');
    return PublishedEventDetails.fromJson(data);
  }
}
