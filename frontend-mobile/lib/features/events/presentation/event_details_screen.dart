import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/oidc_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/event_models.dart';
import '../data/events_repository.dart';
import 'purchase_screen.dart';

class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(publishedEventDetailsProvider(eventId));
    return Scaffold(
      appBar: AppBar(title: const Text('Event details')),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateWidget(
          message: _errorMessage(error),
          icon: Icons.error_outline_rounded,
          onRetry: () => ref.invalidate(publishedEventDetailsProvider(eventId)),
        ),
        data: (event) => _DetailsContent(
          event: event,
          eventId: eventId,
        ),
      ),
    );
  }
}

class _DetailsContent extends ConsumerWidget {
  const _DetailsContent({
    required this.event,
    required this.eventId,
  });
  final PublishedEventDetails event;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = event.start;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ── Hero image ──
        const EventGradientBox(
          height: 200,
          iconSize: 60,
          borderRadius: AppTheme.radiusXl,
        ),
        const SizedBox(height: 22),

        // ── Event name ──
        Text(
          event.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.7,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),

        // ── Info rows ──
        InfoRow(
          icon: Icons.calendar_month_rounded,
          title: 'Date and time',
          value: date == null
              ? 'To be announced'
              : '${date.day}/${date.month}/${date.year} · ${TimeOfDay.fromDateTime(date).format(context)}',
        ),
        const SizedBox(height: 14),
        InfoRow(
          icon: Icons.location_on_rounded,
          title: 'Venue',
          value: event.venue,
        ),

        const SizedBox(height: 30),

        // ── Ticket types header ──
        const SectionHeader(
          title: 'Choose your ticket',
          icon: Icons.confirmation_number_outlined,
        ),

        if (event.ticketTypes.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ticket types are not available for this event yet.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final ticket in event.ticketTypes) ...[
            _TicketTypeCard(
              ticket: ticket,
              event: event,
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Ticket Type Card ─────────────────────────────────────────────────
class _TicketTypeCard extends StatelessWidget {
  const _TicketTypeCard({
    required this.ticket,
    required this.event,
  });

  final EventTicketType ticket;
  final PublishedEventDetails event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Ticket icon ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: AppTheme.purpleLight,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // ── Ticket info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if ((ticket.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      ticket.description!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Price ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ticket.price == 0
                      ? 'Free'
                      : '₹${ticket.price.toStringAsFixed(ticket.price % 1 == 0 ? 0 : 2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.purpleLight,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () async {
                      final auth = EventlyAuth.instance;
                      final token = await auth.getAccessToken();
                      final roles = await auth.getRoles();

                      debugPrint(
                          'TICKETS DEBUG: isLoggedIn = ${auth.isLoggedIn}');
                      debugPrint(
                          'TICKETS DEBUG: hasToken = ${token != null && token.isNotEmpty}');
                      debugPrint('TICKETS DEBUG: roles = $roles');

                      if (!auth.isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please log in before buying a ticket.'),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PurchaseScreen(
                            event: event,
                            ticket: ticket,
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Buy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is DioException &&
      (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403)) {
    return 'Access denied. Check whether published event details are public in Spring Security.';
  }
  if (error is DioException && error.type == DioExceptionType.connectionError) {
    return 'Cannot reach the backend. Check Spring Boot and the API base URL.';
  }
  return 'Could not load this event. Please try again.';
}
