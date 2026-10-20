
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

final ticketQrRepositoryProvider = Provider<TicketQrRepository>((ref) {
  return TicketQrRepository(ref);
});

final ticketQrProvider =
    FutureProvider.family<Uint8List, String>((ref, ticketId) {
  return ref.read(ticketQrRepositoryProvider).getTicketQr(ticketId);
});

class TicketQrRepository {
  TicketQrRepository(this.ref);

  final Ref ref;

  Future<Uint8List> getTicketQr(String ticketId) async {
    final response = await ref.read(dioProvider).get<List<int>>(
      '/api/v1/tickets/$ticketId/qr-codes',
      options: Options(responseType: ResponseType.bytes),
    );

    final data = response.data;

    if (data == null || data.isEmpty) {
      throw const FormatException('Empty QR image response');
    }

    return Uint8List.fromList(data);
  }
}
