import 'package:dio/dio.dart';
import 'package:evently_mobile/core/auth/oidc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../data/event_models.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({
    super.key,
    required this.event,
    required this.ticket,
  });

  final PublishedEventDetails event;
  final EventTicketType ticket;

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isLoading = false;
  bool _isPurchased = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Free';

    return '₹${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}';
  }

  Future<void> _purchaseTicket() async {
    final auth = EventlyAuth.instance;

    if (!auth.isLoggedIn) {
      _showMessage('Please log in before buying a ticket.');
      return;
    }
    if (_isLoading || _isPurchased) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Calls the Spring Boot endpoint to create the ticket.
      // No card details are sent to the backend.
      final response = await ref.read(dioProvider).post(
            '/api/v1/events/${widget.event.id}'
            '/ticket-types/${widget.ticket.id}/tickets',
          );

      if (!mounted) return;

      final statusCode = response.statusCode ?? 0;

      if (statusCode >= 200 && statusCode < 300) {
        setState(() => _isPurchased = true);
      } else {
        _showMessage('Purchase could not be completed.');
      }
    } on DioException catch (error) {
      if (!mounted) return;

      final statusCode = error.response?.statusCode;
      String message;

      if (statusCode == 401) {
        message = 'Please log in to purchase a ticket.';
      } else if (statusCode == 403) {
        message = 'You do not have permission to purchase this ticket.';
      } else if (statusCode == 404) {
        message = 'Event or ticket type not found.';
      } else if (statusCode == 400) {
        message = 'The purchase request was rejected by the server.';
      } else if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        message = 'Cannot connect to the server. Please try again.';
      } else {
        final data = error.response?.data;

        message = data is Map
            ? data['message']?.toString() ??
                'Purchase failed. Please try again.'
            : 'Purchase failed. Please try again.';
      }

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPurchased ? 'Purchase complete' : 'Checkout'),
        automaticallyImplyLeading: !_isLoading && !_isPurchased,
      ),
      body: SafeArea(
        child: _isPurchased ? _buildSuccessScreen() : _buildCheckoutForm(),
      ),
    );
  }

  Widget _buildCheckoutForm() {
    final event = widget.event;
    final ticket = widget.ticket;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header ──
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            size: 28,
            color: AppTheme.purpleLight,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Complete your purchase',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter dummy card details to continue.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // ── Order summary ──
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D45D9), Color(0xFF3D1F8A)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.purpleLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _OrderDetailRow(
                label: 'Ticket',
                value: ticket.name,
              ),
              const SizedBox(height: 6),
              _OrderDetailRow(
                label: 'Venue',
                value: event.venue,
              ),
              if (event.start != null) ...[
                const SizedBox(height: 6),
                _OrderDetailRow(
                  label: 'Date',
                  value:
                      '${event.start!.day}/${event.start!.month}/${event.start!.year}',
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _formatPrice(ticket.price),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.purpleLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        const Text(
          'Card details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // ── Form ──
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Cardholder name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter cardholder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                maxLength: 19,
                decoration: const InputDecoration(
                  labelText: 'Card number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: Icon(Icons.credit_card, size: 20),
                  counterText: '',
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\s'), '');

                  if (!RegExp(r'^\d{16}$').hasMatch(digits)) {
                    return 'Enter 16 digits for the demo';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.datetime,
                      maxLength: 5,
                      decoration: const InputDecoration(
                        labelText: 'Expiry date',
                        hintText: 'MM/YY',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (!RegExp(
                          r'^(0[1-9]|1[0-2])\/\d{2}$',
                        ).hasMatch(value ?? '')) {
                          return 'Use MM/YY';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (!RegExp(r'^\d{3,4}$').hasMatch(value ?? '')) {
                          return 'Enter 3–4 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppTheme.textTertiary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo checkout only. No card is charged, and card '
                  'details are not sent to the server.',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Purchase button ──
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _isLoading ? null : _purchaseTicket,
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Creating your ticket...'),
                    ],
                  )
                : Text(
                    'Buy ticket · ${_formatPrice(ticket.price)}',
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    final event = widget.event;
    final ticket = widget.ticket;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Success icon ──
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ticket purchased!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your ticket has been created successfully.\nView it in "My Tickets" to see your QR code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            // ── Ticket summary ──
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: AppTheme.purpleLight,
                    size: 24,
                  ),
                ),
                title: Text(
                  event.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  ticket.name,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                trailing: Text(
                  _formatPrice(ticket.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.purpleLight,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  // Return to the event list, removing both
                  // checkout and event details from the stack.
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
                icon: const Icon(Icons.explore_rounded, size: 20),
                label: const Text('Back to events'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order detail row widget ──────────────────────────────────────────
class _OrderDetailRow extends StatelessWidget {
  const _OrderDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
