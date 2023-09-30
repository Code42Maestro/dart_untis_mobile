import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';

// We don't care about missing API docs in private api.
// ignore_for_file: public_member_api_docs

class UntisAuthentication {
  static const String _defaultUser = '#anonymous#';

  final String _username;
  late int _otp;
  late int _clientTime;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'user': _username,
        'otp': _otp,
        'clientTime': _clientTime
      };

  /// This constructor uses [DateTime.now()] to calculate an opt code
  UntisAuthentication.currentTime(String? username, String? appSharedSecret)
      : _username = username ?? _defaultUser {
    _clientTime = DateTime.now().millisecondsSinceEpoch;
    _otp = _createTimeBasedCode(_clientTime, appSharedSecret);
  }

  static int _verifyCode(Uint8List key, int time) {
    int j = time; // time is the initialization vector
    final List<int> arrayOfByte = List<int>.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      arrayOfByte[i] = j & 0xFF;
      j >>= 8;
    }

    final Digest digest = Hmac(sha1, key).convert(arrayOfByte);
    final Uint8List hashedKey = digest.bytes as Uint8List;
    int otp = 0;
    for (int i = 0; i < 4; i++) {
      final int l = hashedKey[(hashedKey[19] & 0xF) + i] & 0xFF;
      otp = (otp << 8) | l;
    }
    return (otp & 0x7FFFFFFF) % 1000000;
  }

  static int _createTimeBasedCode(int timestamp, String? appSharedSecret) {
    if (appSharedSecret == null) return 0;
    if (appSharedSecret.isEmpty) return 0;
    return _verifyCode(base32.decode(appSharedSecret.toUpperCase()),
        timestamp ~/ 30000); // Code will change every 30000 milliseconds
  }
}
