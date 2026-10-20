class PublishedEvent {
  const PublishedEvent({
    required this.id,
    required this.name,
    required this.venue,
    this.start,
    this.end,
  });

  final String id;
  final String name;
  final String venue;
  final DateTime? start;
  final DateTime? end;

  factory PublishedEvent.fromJson(Map<String, dynamic> json) {
    return PublishedEvent(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled event',
      venue: json['venue']?.toString() ?? 'Venue to be announced',
      start: _parseDate(json['start']),
      end: _parseDate(json['end']),
    );
  }
}

class EventTicketType {
  const EventTicketType({
    required this.id,
    required this.name,
    required this.price,
    this.description,
  });

  final String id;
  final String name;
  final double price;
  final String? description;

  factory EventTicketType.fromJson(Map<String, dynamic> json) {
    return EventTicketType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'General admission',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString(),
    );
  }
}

class PublishedEventDetails extends PublishedEvent {
  const PublishedEventDetails({
    required super.id,
    required super.name,
    required super.venue,
    super.start,
    super.end,
    required this.ticketTypes,
  });

  final List<EventTicketType> ticketTypes;

  factory PublishedEventDetails.fromJson(Map<String, dynamic> json) {
    final types = (json['ticketTypes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EventTicketType.fromJson)
        .toList(growable: false);
    return PublishedEventDetails(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled event',
      venue: json['venue']?.toString() ?? 'Venue to be announced',
      start: _parseDate(json['start']),
      end: _parseDate(json['end']),
      ticketTypes: types,
    );
  }
}

class PublishedEventPage {
  const PublishedEventPage({required this.events, required this.totalPages});

  final List<PublishedEvent> events;
  final int totalPages;

  factory PublishedEventPage.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PublishedEvent.fromJson)
        .toList(growable: false);
    return PublishedEventPage(
      events: content,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
