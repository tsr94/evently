class TicketQrModel {
  const TicketQrModel({required this.value});

  final String value;

  factory TicketQrModel.fromJson(dynamic json) {
    if (json is String && json.isNotEmpty) {
      return TicketQrModel(value: json);
    }

    if (json is Map) {
      final value = json['type'] ?? json['value'];

      if (value is String && value.isNotEmpty) {
        return TicketQrModel(value: value);
      }
    }

    throw const FormatException('Invalid QR code response');
  }
}