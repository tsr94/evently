import 'package:flutter/material.dart';
import 'package:evently_mobile/features/organizer/data/organizer_event_repository.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({
    super.key,
    required this.repository,
    this.eventId,
  });

  final OrganizerEventRepository repository;
  final String? eventId;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _TicketTypeFields {
  _TicketTypeFields({
    String? id,
    String name = '',
    String price = '0',
    String quantity = '100',
    String description = '',
  })  : id = id,
        name = TextEditingController(text: name),
        price = TextEditingController(text: price),
        quantity = TextEditingController(text: quantity),
        description = TextEditingController(text: description);

  final String? id;
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController quantity;
  final TextEditingController description;

  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
    description.dispose();
  }
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _salesStart = TextEditingController();
  final _salesEnd = TextEditingController();

  final List<_TicketTypeFields> _ticketTypes = [
    _TicketTypeFields(name: 'General admission', price: '0', quantity: '100'),
  ];

  String _status = 'DRAFT';
  bool _loading = false;
  bool _saving = false;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() => _loading = true);

    try {
      final event = await widget.repository.getEvent(widget.eventId!);
      final rawTicketTypes = event['ticketTypes'] as List? ?? [];

      final loadedTicketTypes = rawTicketTypes.map((raw) {
        final ticket = Map<String, dynamic>.from(raw as Map);
        return _TicketTypeFields(
          id: ticket['id']?.toString(),
          name: ticket['name']?.toString() ?? 'General admission',
          price: ticket['price']?.toString() ?? '0',
          quantity: ticket['totalAvailable']?.toString() ?? '100',
          description: ticket['description']?.toString() ?? '',
        );
      }).toList();

      if (!mounted) return;

      _name.text = event['name']?.toString() ?? '';
      _venue.text = event['venue']?.toString() ?? '';
      _start.text = event['start']?.toString() ?? '';
      _end.text = event['end']?.toString() ?? '';
      _salesStart.text = event['salesStart']?.toString() ?? '';
      _salesEnd.text = event['salesEnd']?.toString() ?? '';
      _status = event['status']?.toString() ?? 'DRAFT';

      for (final ticket in _ticketTypes) {
        ticket.dispose();
      }
      _ticketTypes
        ..clear()
        ..addAll(
          loadedTicketTypes.isEmpty
              ? [
                  _TicketTypeFields(
                    name: 'General admission',
                    price: '0',
                    quantity: '100',
                  ),
                ]
              : loadedTicketTypes,
        );

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load event: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validPrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a price';
    }
    final price = double.tryParse(value.trim());
    if (price == null || price < 0) return 'Enter a valid price';
    return null;
  }

  String? _validQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a capacity';
    }
    final quantity = int.tryParse(value.trim());
    if (quantity == null || quantity < 0) return 'Enter a valid capacity';
    return null;
  }

  Map<String, dynamic> _dateFields() {
    final result = <String, dynamic>{};

    for (final entry in {
      'start': _start.text,
      'end': _end.text,
      'salesStart': _salesStart.text,
      'salesEnd': _salesEnd.text,
    }.entries) {
      if (entry.value.trim().isNotEmpty) {
        result[entry.key] = entry.value.trim();
      }
    }

    return result;
  }

  Future<void> _showTicketTypeDialog({int? index}) async {
    final existing = index == null ? null : _ticketTypes[index];
    final fields = _TicketTypeFields(
      id: existing?.id,
      name: existing?.name.text ?? '',
      price: existing?.price.text ?? '0',
      quantity: existing?.quantity.text ?? '100',
      description: existing?.description.text ?? '',
    );
    final dialogFormKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(index == null ? 'Add ticket tier' : 'Edit ticket tier'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Ticket name', fields.name,
                      validator: _required, hint: 'e.g. VIP balcony'),
                  _field(
                    'Price (USD)',
                    fields.price,
                    validator: _validPrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '65.00',
                  ),
                  _field(
                    'Capacity',
                    fields.quantity,
                    validator: _validQuantity,
                    keyboardType: TextInputType.number,
                    hint: '320',
                  ),
                  TextFormField(
                    controller: fields.description,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'What does this ticket include?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (dialogFormKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(index == null ? 'Add tier' : 'Save changes'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        if (index == null) {
          _ticketTypes.add(fields);
        } else {
          _ticketTypes[index].dispose();
          _ticketTypes[index] = fields;
        }
      });
    } else {
      fields.dispose();
    }
  }

  void _removeTicketType(int index) {
    if (_ticketTypes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one ticket type is required')),
      );
      return;
    }

    setState(() {
      _ticketTypes.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tickets = <Map<String, dynamic>>[];
    for (final fields in _ticketTypes) {
      tickets.add({
        if (_isEditing && fields.id != null) 'id': fields.id,
        'name': fields.name.text.trim(),
        'price': double.parse(fields.price.text.trim()),
        'totalAvailable': int.parse(fields.quantity.text.trim()),
        'description': fields.description.text.trim(),
      });
    }

    setState(() => _saving = true);

    try {
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'venue': _venue.text.trim(),
        'status': _status,
        'ticketTypes': tickets,
        ..._dateFields(),
      };

      if (_isEditing) {
        body['id'] = widget.eventId;
        await widget.repository.updateEvent(widget.eventId!, body);
      } else {
        await widget.repository.createEvent(body);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Event updated successfully'
                : 'Event created successfully',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save event: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _ticketTypeCard(int index) {
    final ticket = _ticketTypes[index];
    final name = ticket.name.text.trim().isEmpty
        ? 'Untitled ticket tier'
        : ticket.name.text.trim();
    final quantity = int.tryParse(ticket.quantity.text.trim());
    final price = double.tryParse(ticket.price.text.trim());

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _saving ? null : () => _showTicketTypeDialog(index: index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.confirmation_number_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quantity ?? ticket.quantity.text} tickets · ${ticket.description.text.trim().isEmpty ? 'No description' : ticket.description.text.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price == null ? '—' : '₹${price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                tooltip: 'Edit ticket tier',
                onPressed: _saving ? null : () => _showTicketTypeDialog(index: index),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Remove ticket tier',
                onPressed: _saving ? null : () => _removeTicketType(index),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _start.dispose();
    _end.dispose();
    _salesStart.dispose();
    _salesEnd.dispose();
    for (final ticket in _ticketTypes) {
      ticket.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Event details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _field('Event name', _name, validator: _required),
                  _field('Venue', _venue, validator: _required),
                  _field(
                    'Start date and time',
                    _start,
                    hint: '2026-11-20T09:00:00',
                  ),
                  _field(
                    'End date and time',
                    _end,
                    hint: '2026-11-20T18:00:00',
                  ),
                  _field(
                    'Ticket sales start',
                    _salesStart,
                    hint: '2026-10-20T09:00:00',
                  ),
                  _field(
                    'Ticket sales end',
                    _salesEnd,
                    hint: '2026-11-19T23:59:00',
                  ),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Event status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                      DropdownMenuItem(
                        value: 'PUBLISHED',
                        child: Text('Published'),
                      ),
                      DropdownMenuItem(
                        value: 'CANCELLED',
                        child: Text('Cancelled'),
                      ),
                      DropdownMenuItem(
                        value: 'COMPLETED',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tickets',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving ? null : () => _showTicketTypeDialog(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add tier'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    _ticketTypes.length,
                    (index) => _ticketTypeCard(index),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : _isEditing
                              ? 'Save changes'
                              : 'Create event',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
