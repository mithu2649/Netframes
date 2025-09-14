import 'dart:math';

class JsUnpacker {
  final String? _packedJS;

  JsUnpacker(this._packedJS);

  bool detect() {
    if (_packedJS == null) return false;
    final js = _packedJS!.replaceAll(' ', '');
    final p = RegExp(r"eval\(function\(p,a,c,k,e,[rd]");
    return p.hasMatch(js);
  }

  // String? unpack() {
  //   final js = _packedJS;
  //   if (js == null) return null;

  //   try {
  //     final p = RegExp(
  //         "\\}\\s*\\('(.+?)'\\,\\s*(.+?),(\\d+),'(.*?)'\\.split('\\|'\\)",
  //         dotAll: true);
  //     final m = p.firstMatch(js);

  //     if (m != null && m.groupCount == 4) {
  //       final payload = m.group(1)!.replaceAll(r"'", "'");
  //       final radixStr = m.group(2)!;
  //       final countStr = m.group(3)!;
  //       final symtab = m.group(4)!.split('|');

  //       print("--- Unpacker ---");
  //       print("Payload: $payload");
  //       print("Radix: $radixStr");
  //       print("Count: $countStr");
  //       print("Symtab: $symtab");

  //       int radix = 36;
  //       int count = 0;

  //       try {
  //         radix = int.parse(radixStr);
  //       } catch (e) {
  //         // ignore
  //       }
  //       try {
  //         count = int.parse(countStr);
  //       } catch (e) {
  //         // ignore
  //       }

  //       if (symtab.length != count) {
  //         throw Exception("Unknown p.a.c.k.e.r. encoding");
  //       }

  //       final unbase = _Unbase(radix);
  //       final wordRegex = RegExp(r"\\b\\w+\\b");
  //       var decoded = payload;

  //       final matches = wordRegex.allMatches(payload).toList().reversed;

  //       for (var match in matches) {
  //         final word = match.group(0)!;
  //         final x = unbase.unbase(word);
  //         String? value;
  //         if (x < symtab.length) {
  //           value = symtab[x];
  //         }

  //         if (value != null && value.isNotEmpty) {
  //           decoded = decoded.substring(0, match.start) + value + decoded.substring(match.end);
  //         }
  //       }
  //       print("--- Decoded Payload ---");
  //       print(decoded);
  //       return decoded;
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  //   return null;
  // }

  String? unpack() {
  final js = _packedJS;
  if (js == null) return null;

  try {
    final p = RegExp(
      r"""\}\s*\('(.*?)',\s*(.*?),\s*(\d+),\s*'(.*?)'\.split\('\|'\)""",
      dotAll: true,
    );
    final m = p.firstMatch(js);

    if (m != null && m.groupCount == 4) {
      final payload = m.group(1)!.replaceAll(r"\'", "'");
      final radixStr = m.group(2)!;
      final countStr = m.group(3)!;
      final symtab = m.group(4)!.split('|');

      int radix = int.tryParse(radixStr) ?? 36;
      int count = int.tryParse(countStr) ?? 0;

      if (symtab.length != count) {
        throw Exception("Unknown p.a.c.k.e.r. encoding");
      }

      final unbase = _Unbase(radix);
      final wordRegex = RegExp(r"\b\w+\b");
      var decoded = payload;

      final matches = wordRegex.allMatches(payload).toList().reversed;
      for (var match in matches) {
        final word = match.group(0)!;
        final x = unbase.unbase(word);
        if (x < symtab.length) {
          final value = symtab[x];
          if (value.isNotEmpty) {
            decoded = decoded.substring(0, match.start) + value + decoded.substring(match.end);
          }
        }
      }
      return decoded;
    }
  } catch (e) {
    print("Unpack error: $e");
  }
  return null;
}

}

class _Unbase {
  final int radix;
  String? _alphabet;
  Map<String, int>? _dictionary;

  static const String _alphabet62 =
      "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  static const String _alphabet95 =
      " !\"#\u0024%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

  _Unbase(this.radix) {
    if (radix > 36) {
      if (radix < 62) {
        _alphabet = _alphabet62.substring(0, radix);
      } else if (radix >= 63 && radix <= 94) {
        _alphabet = _alphabet95.substring(0, radix);
      } else if (radix == 62) {
        _alphabet = _alphabet62;
      } else if (radix == 95) {
        _alphabet = _alphabet95;
      }

      if (_alphabet != null) {
        _dictionary = {};
        for (int i = 0; i < _alphabet!.length; i++) {
          _dictionary![_alphabet![i]] = i;
        }
      }
    }
  }

  int unbase(String str) {
    int ret = 0;
    if (_alphabet == null) {
      try {
        ret = int.parse(str, radix: radix);
      } catch(e) {
        // Fallback for when the number is not in the expected radix, but a simple integer
        try {
          ret = int.parse(str);
        } catch (e2) {
          return 0;
        }
      }
    } else {
      final tmp = str.split('').reversed.join('');
      for (int i = 0; i < tmp.length; i++) {
        ret += (pow(radix, i) * _dictionary![tmp[i]]!).toInt();
      }
    }
    return ret;
  }
}