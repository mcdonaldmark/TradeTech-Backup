import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class ImageHelper {
  static bool isBase64(String? data) {
    if (data == null || data.isEmpty) return false;

    // reject file paths (your current bug)
    if (data.startsWith("/") ||
        data.contains("cache") ||
        data.contains(".jpg") ||
        data.contains(".png")) {
      return false;
    }

    return true;
  }

  static Uint8List? decode(String? data) {
    if (!isBase64(data)) return null;

    try {
      return base64Decode(data!);
    } catch (_) {
      return null;
    }
  }
}