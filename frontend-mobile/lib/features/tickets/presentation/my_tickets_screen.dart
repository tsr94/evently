import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ticket_qr_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/ticket_models.dart';
import '../data/tickets_repository.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key, this.embedded = false});

  /// When true, hides the AppBar (used inside bottom nav).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(myTicketsProvider);

    return Scaffold(
      appBar: embedded
          ? AppBar(
              automaticallyImplyLeading: false,
              title: const Text('My Tickets'),
              actions: [
                IconButton(
                  tooltip: 'Refresh tickets',
                  onPressed: () => ref.invalidate(myTicketsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            )
          : AppBar(
              title: const Text('My Tickets'),
              actions: [
                IconButton(
                  tooltip: 'Refresh tickets',
                  onPressed: () => ref.invalidate(myTicketsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
      body: result.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => ErrorStateWidget(
          message: error is DioException &&
                  (error.response?.statusCode == 401 ||
                      error.response?.statusCode == 403)
              ? 'Please log in to view your tickets.'
              : 'Could not load your tickets.',
          icon: error is DioException &&
                  (error.response?.statusCode == 401 ||
                      error.response?.statusCode == 403)
              ? Icons.lock_outline_rounded
              : Icons.error_outline_rounded,
          onRetry: () => ref.invalidate(myTicketsProvider),
        ),
        data: (page) {
          if (page.tickets.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.confirmation_number_outlined,
              title: 'No tickets yet',
              subtitle:
                  'Tickets you purchase will appear here.\nBrowse events to find something exciting!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myTicketsProvider);
              await ref.read(myTicketsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: page.tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = page.tickets[index];
                return _TicketCard(ticket: ticket);
              },
            ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final TicketModel ticket;

  @override
  Widget build(BuildContext context) {
    final isCancelled = ticket.status.toUpperCase() == 'CANCELLED';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketQrScreen(
                ticketId: ticket.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ticket icon ──
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: AppTheme.purpleLight,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // ── Ticket info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.ticketName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ticket.eventName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            ticket.eventVenue,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ticket.eventStart != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${_formatEventDate(ticket.eventStart!)}'
                              '${ticket.eventEnd != null ? ' – ${_formatEventDate(ticket.eventEnd!)}' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StatusBadge(label: ticket.status),
                        const Spacer(),
                        Text(
                          ticket.price == 0
                              ? 'Free'
                              : '₹${ticket.price.toStringAsFixed(ticket.price % 1 == 0 ? 0 : 2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.purpleLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 16,
                            color: AppTheme.purpleLight,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Tap to view QR code',
                            style: TextStyle(
                              color: AppTheme.purpleLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatEventDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  final year = date.year;
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '$day $month $year, $hour:$minute $period';
}
