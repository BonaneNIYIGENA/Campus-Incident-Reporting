import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

abstract class ImageUploader {
  Future<String> upload(File file, {required String folder});
}

class ImageUploadFailure implements Exception {
  const ImageUploadFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class CloudinaryUploader implements ImageUploader {
  CloudinaryUploader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _endpoint = Uri.parse(
    'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
  );

  @override
  Future<String> upload(File file, {required String folder}) async {
    if (await file.length() > CloudinaryConfig.maxBytes) {
      throw const ImageUploadFailure('That photo is too large. Pick one under 5 MB.');
    }
    final request = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    try {
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 40)),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final url = body['secure_url'] as String?;
      if (response.statusCode != 200 || url == null) {
        throw ImageUploadFailure(
          (body['error'] as Map?)?['message'] as String? ??
              'The photo could not be uploaded.',
        );
      }
      return url;
    } on ImageUploadFailure {
      rethrow;
    } catch (_) {
      throw const ImageUploadFailure('The photo could not be uploaded. Check your connection.');
    }
  }
}

// Inserts a transformation so lists download a small cropped copy instead of the original.
String cloudinaryThumb(String url, {int size = 200}) {
  const marker = '/image/upload/';
  final at = url.indexOf(marker);
  if (!url.contains('res.cloudinary.com') || at < 0) return url;
  final cut = at + marker.length;
  return '${url.substring(0, cut)}c_fill,w_$size,h_$size,q_auto,f_auto/${url.substring(cut)}';
}
