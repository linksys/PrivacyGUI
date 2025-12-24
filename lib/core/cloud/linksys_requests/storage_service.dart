import 'package:http/http.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

import '../../../constants/_constants.dart';

extension StorageService on LinksysHttpClient {
  Future<Response> deviceUpload({
    required String deviceToken,
    required String serialNumber,
    required String meta,
    required String log,
  }) async {
    final endpoint = combineUrl(kDeviceUpload);
    final header = defaultHeader
      ..['dataType'] = 'json'
      ..['X-Linksys-Token'] = deviceToken
      ..['X-Linksys-SN'] = serialNumber
      ..['content-type'] = 'multipart/form-data';
    final metaMultipart = MultipartFile.fromBytes(
      'meta',
      meta.codeUnits,
      filename: 'meta.txt',
      contentType: MediaType('text', 'plain'),
    );
    final logMultipart = MultipartFile.fromBytes(
      'log',
      log.codeUnits,
      filename: 'log.txt',
      contentType: MediaType('text', 'plain'),
    );
    return await upload(Uri.parse(endpoint), [metaMultipart, logMultipart],
        headers: header);
  }
}
