import 'dart:convert';
import 'dart:typed_data';

/// Byte-oriented TCP framing for Frosthaven Assistant messages.
///
/// Frames use `S3nD:<utf8-byte-length>:<utf8-payload>`. Parsing bytes before
/// decoding prevents TCP chunk boundaries from splitting UTF-8 characters.
class MessageFramer {
  static const int maxPayloadBytes = 5 * 1024 * 1024;
  static final Uint8List _prefix = Uint8List.fromList(ascii.encode('S3nD:'));

  final List<int> _buffer = [];

  static Uint8List encode(String message) {
    final payload = utf8.encode(message);
    if (payload.length > maxPayloadBytes) {
      throw const FormatException('Message exceeds maximum payload size');
    }
    return Uint8List.fromList([
      ..._prefix,
      ...ascii.encode('${payload.length}:'),
      ...payload,
    ]);
  }

  List<String> add(List<int> bytes) {
    _buffer.addAll(bytes);
    final messages = <String>[];

    while (true) {
      if (_buffer.length < _prefix.length) break;
      for (var i = 0; i < _prefix.length; i++) {
        if (_buffer[i] != _prefix[i]) {
          _buffer.clear();
          throw const FormatException('Invalid message prefix');
        }
      }

      final lengthStart = _prefix.length;
      final separator = _buffer.indexOf(58, lengthStart); // ':'
      if (separator == -1) {
        if (_buffer.length - lengthStart > 10) {
          _buffer.clear();
          throw const FormatException('Invalid message length');
        }
        break;
      }

      final lengthText = ascii.decode(_buffer.sublist(lengthStart, separator));
      final payloadLength = int.tryParse(lengthText);
      if (payloadLength == null ||
          payloadLength < 0 ||
          payloadLength > maxPayloadBytes) {
        _buffer.clear();
        throw const FormatException('Invalid message length');
      }

      final payloadStart = separator + 1;
      final frameLength = payloadStart + payloadLength;
      if (_buffer.length < frameLength) break;

      messages.add(
        utf8.decode(
          _buffer.sublist(payloadStart, frameLength),
          allowMalformed: false,
        ),
      );
      _buffer.removeRange(0, frameLength);
    }

    return messages;
  }

  void reset() => _buffer.clear();
}
