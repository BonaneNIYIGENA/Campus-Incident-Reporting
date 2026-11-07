import 'dart:convert';
import 'dart:io';

import 'package:cir/services/image_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late File photo;

  setUp(() {
    photo = File('${Directory.systemTemp.path}/cir_upload_test.jpg')
      ..writeAsBytesSync([1, 2, 3, 4]);
  });

  tearDown(() {
    if (photo.existsSync()) photo.deleteSync();
  });

  test('sends the preset and folder and returns the secure url', () async {
    late http.BaseRequest sent;
    final client = MockClient.streaming((request, body) async {
      sent = request;
      final json = jsonEncode({
        'secure_url':
            'https://res.cloudinary.com/dgxaazbuq/image/upload/v1/a.jpg',
      });
      return http.StreamedResponse(Stream.value(utf8.encode(json)), 200);
    });

    final url = await CloudinaryUploader(client: client)
        .upload(photo, folder: 'cir/incidents');

    expect(url, startsWith('https://res.cloudinary.com/dgxaazbuq/'));
    expect(sent.url.host, 'api.cloudinary.com');
    expect(sent.url.path, '/v1_1/dgxaazbuq/image/upload');
    final fields = (sent as http.MultipartRequest).fields;
    expect(fields['upload_preset'], 'cir_uploads');
    expect(fields['folder'], 'cir/incidents');
  });

  test('a rejected upload surfaces the Cloudinary message', () async {
    final client = MockClient.streaming((request, body) async {
      final json = jsonEncode({
        'error': {'message': 'Upload preset not found'},
      });
      return http.StreamedResponse(Stream.value(utf8.encode(json)), 400);
    });

    expect(
      CloudinaryUploader(client: client).upload(photo, folder: 'cir/profiles'),
      throwsA(
        isA<ImageUploadFailure>().having(
          (e) => e.message,
          'message',
          'Upload preset not found',
        ),
      ),
    );
  });

  test('a network failure becomes a friendly message', () async {
    final client = MockClient.streaming(
      (request, body) async => throw const SocketException('offline'),
    );
    expect(
      CloudinaryUploader(client: client).upload(photo, folder: 'cir/profiles'),
      throwsA(isA<ImageUploadFailure>()),
    );
  });

  test('thumbnail urls get a crop transformation', () {
    expect(
      cloudinaryThumb(
        'https://res.cloudinary.com/dgxaazbuq/image/upload/v1/cir/a.jpg',
      ),
      'https://res.cloudinary.com/dgxaazbuq/image/upload/c_fill,w_200,h_200,q_auto,f_auto/v1/cir/a.jpg',
    );
    expect(
      cloudinaryThumb('https://example.com/a.jpg'),
      'https://example.com/a.jpg',
    );
  });
}
