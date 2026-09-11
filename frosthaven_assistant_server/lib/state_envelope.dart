import 'dart:convert';

/// Canonical, wire-compatible state synchronization envelope.
class StateEnvelope {
  const StateEnvelope({
    required this.index,
    required this.description,
    required this.eventJson,
    required this.state,
  });

  final int index;
  final String description;
  final String eventJson;
  final String state;

  String encode() => jsonEncode({
        'i': index,
        'd': description,
        'e': jsonDecode(eventJson),
        's': state,
      });

  static StateEnvelope? tryDecode(String content) {
    if (!content.startsWith('{')) return null;
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return StateEnvelope(
        index: map['i'] as int,
        description: map['d'] as String,
        eventJson: jsonEncode(map['e'] as Object),
        state: map['s'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
