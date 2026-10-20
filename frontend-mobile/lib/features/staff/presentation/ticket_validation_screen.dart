
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_client.dart';

class TicketValidationScreen extends ConsumerStatefulWidget {
  const TicketValidationScreen({super.key});

  @override
  ConsumerState<TicketValidationScreen> createState() =>
      _TicketValidationScreenState();
}

class _TicketValidationScreenState
    extends ConsumerState<TicketValidationScreen> {
  final _ticketIdController = TextEditingController();
  final _scannerController = MobileScannerController();

  bool _loading = false;
  bool _scannerVisible = false;

  String? _result;
  String? _resultTicketId;
  String? _error;

  @override
  void dispose() {
    _ticketIdController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _validateTicket(
    String ticketId, {
    required String method,
  }) async {
    final id = ticketId.trim();

    if (id.isEmpty) {
      setState(() {
        _error = 'Please enter or scan a ticket ID.';
        _result = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _resultTicketId = null;
    });

    print('Scanned QR value: $id');
    print('Scanned value length: ${id.length}');

    try {
      final response = await ref.read(dioProvider).post(
        '/api/v1/ticket-validations',
        data: {
          'id': id,
          'method': method,
        },
      );
      

      if (!mounted) return;

      final data = Map<String, dynamic>.from(response.data as Map);
      final status = data['status']?.toString().toUpperCase();

      if (!{'VALID', 'INVALID', 'EXPIRED'}.contains(status)) {
        setState(() {
          _error = 'Unexpected validation response from server.';
        });
        return;
      }

      setState(() {
        _result = status;
        _resultTicketId = data['ticketId']?.toString() ?? id;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      final code = e.response?.statusCode;

      setState(() {
        _error = code == 401 || code == 403
            ? 'Access denied. Sign in with an authorized staff account.'
            : e.response?.data is Map &&
                    e.response?.data['message'] != null
                ? e.response?.data['message'].toString()
                : 'Could not validate ticket. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unexpected response. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_loading) return;

    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;

    if (value == null || value.trim().isEmpty) return;

    // Prevent repeated camera detections while processing.
    setState(() {
      _scannerVisible = false;
    });

    _scannerController.stop();

    // The QR payload must contain the ticket UUID.
    _validateTicket(value, method: 'QR_SCAN');
  }

  Color _resultColor(String status) {
    switch (status) {
      case 'VALID':
        return Colors.green;
      case 'EXPIRED':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _resultIcon(String status) {
    switch (status) {
      case 'VALID':
        return Icons.check_circle;
      case 'EXPIRED':
        return Icons.schedule;
      default:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _result;
    final resultColor =
        status == null ? null : _resultColor(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Validation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Scan a ticket QR code or enter its ID manually.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    setState(() {
                      _scannerVisible = !_scannerVisible;
                      _error = null;
                    });

                    if (_scannerVisible) {
                      await _scannerController.start();
                    } else {
                      await _scannerController.stop();
                    }

                    if (!mounted) return;
                    setState(() {});
                  },
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(
              _scannerVisible ? 'Close Scanner' : 'Scan QR Code',
            ),
          ),

          if (_scannerVisible) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 300,
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),
          const Row(
            children: [
              Icon(Icons.keyboard),
              SizedBox(width: 8),
              Text(
                'Manual validation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _ticketIdController,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Ticket UUID',
              hintText: 'Enter ticket ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          FilledButton(
            onPressed: _loading
                ? null
                : () => _validateTicket(
                      _ticketIdController.text,
                      method: 'MANUAL',
                    ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Validate Ticket'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 20),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],

          if (status != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _resultIcon(status),
                      color: resultColor,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Ticket ID: $_resultTicketId'),
                    if (status == 'VALID') ...[
                      const SizedBox(height: 8),
                      const Text('Ticket accepted.'),
                    ] else if (status == 'EXPIRED') ...[
                      const SizedBox(height: 8),
                      const Text('This ticket has expired.'),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('This ticket is not valid.'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
