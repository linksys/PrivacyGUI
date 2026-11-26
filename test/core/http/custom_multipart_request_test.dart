// CustomMultipartRequest: the body of the manual firmware upload
// (LinksysHttpClient.upload). It is package:http's MultipartRequest with its
// own boundary prefix and a file part that names its content type first.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/http/custom_multipart_request.dart';

/// The request's body and the boundary its content type names.
Future<(String boundary, List<int> body)> _finalized(
    CustomMultipartRequest request) async {
  final body = await request.finalize().toBytes();
  final boundary = RegExp(r'^multipart/form-data; boundary=(\S+)$')
      .firstMatch(request.headers['content-type']!)!
      .group(1)!;
  return (boundary, body);
}

void main() {
  CustomMultipartRequest request() =>
      CustomMultipartRequest('POST', Uri.parse('https://192.168.1.1/jcgi/'));

  test('a field is a part of its own, under its name', () async {
    final upload = request()..fields['X-JNAP-Action'] = 'updatefirmware';

    final (boundary, body) = await _finalized(upload);

    expect(
        utf8.decode(body),
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="X-JNAP-Action"\r\n'
        '\r\n'
        'updatefirmware\r\n'
        '--$boundary--\r\n');
  });

  test(
      'a field that is not plain ASCII says it is UTF-8 text, sent as binary',
      () async {
    final upload = request()..fields['name'] = 'Café';

    final (boundary, body) = await _finalized(upload);

    expect(
        utf8.decode(body),
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="name"\r\n'
        'content-type: text/plain; charset=utf-8\r\n'
        'content-transfer-encoding: binary\r\n'
        '\r\n'
        'Café\r\n'
        '--$boundary--\r\n');
  });

  test('a file names its content type, then its field and file name',
      () async {
    final upload = request()
      ..files.add(MultipartFile.fromBytes('upload', [0, 255, 7],
          filename: 'FW_M63.img'));

    final (boundary, body) = await _finalized(upload);

    expect(body, [
      ...utf8.encode('--$boundary\r\n'
          'content-type: application/octet-stream\r\n'
          'Content-Disposition: form-data; name="upload"; '
          'filename="FW_M63.img"\r\n'
          '\r\n'),
      0, 255, 7,
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ]);
  });

  test('a file without a file name gives only its field', () async {
    final upload = request()..files.add(MultipartFile.fromString('log', 'x'));

    final (boundary, body) = await _finalized(upload);

    expect(
        utf8.decode(body),
        '--$boundary\r\n'
        'content-type: text/plain; charset=utf-8\r\n'
        'Content-Disposition: form-data; name="log"\r\n'
        '\r\n'
        'x\r\n'
        '--$boundary--\r\n');
  });

  // As browsers do: line breaks and quotes would end the header early.
  test('quotes and line breaks in a name are escaped', () async {
    final upload = request()
      ..fields['a"b\r\nc'] = 'v'
      ..files.add(MultipartFile.fromBytes('f', [1], filename: 'x"y\nz.img'));

    final (_, body) = await _finalized(upload);
    final text = latin1.decode(body);

    expect(text, contains('name="a%22b%0D%0Ac"'));
    expect(text, contains('filename="x%22y%0D%0Az.img"'));
  });

  test('fields go before files', () async {
    final upload = request()
      ..files.add(MultipartFile.fromBytes('upload', [1], filename: 'f.img'))
      ..fields['X-JNAP-Action'] = 'updatefirmware';

    final (_, body) = await _finalized(upload);
    final text = latin1.decode(body);

    expect(text.indexOf('name="X-JNAP-Action"'),
        lessThan(text.indexOf('name="upload"')));
  });

  test('the content length it declares is the length of its body', () async {
    final upload = request()
      ..fields['X-JNAP-Action'] = 'updatefirmware'
      ..fields['note'] = 'Café'
      ..files.add(MultipartFile.fromBytes('upload', List.filled(1000, 9),
          filename: 'FW_M63.img'));

    final declared = upload.contentLength;
    final (_, body) = await _finalized(upload);

    expect(declared, body.length);
  });

  test('the boundary is CustomBoundary and 20 boundary characters', () async {
    final (boundary, _) = await _finalized(request()..fields['a'] = 'b');

    expect(boundary, matches(RegExp(r'^CustomBoundary[0-9A-Za-z]{20}$')));
  });

  test('its content length cannot be set', () {
    expect(() => request().contentLength = 10, throwsUnsupportedError);
  });

  test('isPlainAscii tells ASCII text from the rest', () {
    expect(isPlainAscii('updatefirmware'), isTrue);
    expect(isPlainAscii('Café'), isFalse);
  });
}
