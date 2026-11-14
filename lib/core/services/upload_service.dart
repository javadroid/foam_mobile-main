import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/safe_network_image.dart';
import 'package:http/http.dart' as http;

class UploadService {
  /// Upload a single image/document to the backend `/api/upload` endpoint.
  /// Returns the publicly accessible URL string of the uploaded file, or null on error.
  static Future<String?> uploadImage(File file, {String? token}) async {
    try {
      final uri = Uri.parse('${Constants.url}/api/upload');
      final request = http.MultipartRequest('POST', uri);

      String authToken = token ?? '';
      if (authToken.isEmpty && HiveClass.tokenExist()) {
        authToken = HiveClass.getToken();
      }
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Attach file using multipart stream
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['url'] != null) {
          final resolved = resolveImageUrl(data['url'] as String);
          debugPrint('Upload success: $resolved (raw: ${data['url']})');
          return resolved;
        }
      } else {
        debugPrint('Upload failed (${response.statusCode}): ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('Error uploading image: $e\n$stack');
    }
    return null;
  }

  /// Upload multiple images/documents to the backend `/api/upload/multiple` endpoint.
  /// Returns a list of public URLs.
  static Future<List<String>> uploadMultipleImages(List<File> files, {String? token}) async {
    final List<String> urls = [];
    if (files.isEmpty) return urls;

    try {
      final uri = Uri.parse('${Constants.url}/api/upload/multiple');
      final request = http.MultipartRequest('POST', uri);

      String authToken = token ?? '';
      if (authToken.isEmpty && HiveClass.tokenExist()) {
        authToken = HiveClass.getToken();
      }
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      for (final file in files) {
        request.files.add(
          await http.MultipartFile.fromPath('files', file.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['files'] is List) {
          for (final item in data['files']) {
            if (item['url'] != null) {
              urls.add(resolveImageUrl(item['url'] as String));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error uploading multiple images: $e');
    }
    return urls;
  }
}
