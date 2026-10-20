

class TicketModel {
  const TicketModel({
    required this.id,
    required this.status,
    required this.ticketTypeId,
    required this.ticketName,
    required this.price,
    required this.eventId,
    required this.eventName,
    required this.eventVenue,
    this.eventStart,
    this.eventEnd,
  });

  final String id;
  final String status;

  // Purchased ticket type
  final String ticketTypeId;
  final String ticketName;
  final double price;

  // Associated event
  final String eventId;
  final String eventName;
  final String eventVenue;
  final DateTime? eventStart;
  final DateTime? eventEnd;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final ticketType = json['ticketType'] is Map
        ? Map<String, dynamic>.from(json['ticketType'] as Map)
        : <String, dynamic>{};

    final event = json['event'] is Map
        ? Map<String, dynamic>.from(json['event'] as Map)
        : <String, dynamic>{};

    return TicketModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PURCHASED',

      ticketTypeId: ticketType['id']?.toString() ?? '',
      ticketName: ticketType['name']?.toString() ?? 'Event ticket',
      price: (ticketType['price'] as num?)?.toDouble() ?? 0,

      eventId: event['id']?.toString() ?? '',
      eventName: event['name']?.toString() ?? 'Event details unavailable',
      eventVenue: event['venue']?.toString() ?? 'Venue to be announced',
      eventStart: _parseDate(event['start']),
      eventEnd: _parseDate(event['end']),
    );
  }
}

class TicketPage {
  const TicketPage({
    required this.tickets,
    required this.totalPages,
  });

  final List<TicketModel> tickets;
  final int totalPages;

  factory TicketPage.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => TicketModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);

    return TicketPage(
      tickets: content,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class TicketDetails {
  const TicketDetails({
    required this.id,
    required this.status,
    required this.price,
    required this.eventName,
    required this.eventVenue,
    this.description,
    this.eventStart,
    this.eventEnd,
  });

  final String id;
  final String status;
  final double price;
  final String eventName;
  final String eventVenue;
  final String? description;
  final DateTime? eventStart;
  final DateTime? eventEnd;

  factory TicketDetails.fromJson(Map<String, dynamic> json) {
    return TicketDetails(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PURCHASED',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      eventName: json['eventName']?.toString() ?? 'Event ticket',
      eventVenue:
          json['eventVenue']?.toString() ?? 'Venue to be announced',
      description: json['description']?.toString(),
      eventStart: _parseDate(json['eventStart']),
      eventEnd: _parseDate(json['eventEnd']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
