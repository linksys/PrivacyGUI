import 'dart:convert';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/cloud/model/create_ticket.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

extension Cloud2Service on LinksysHttpClient {
  Future<Response> createTicket(
      {required CreateTicketInput createTicketInput,
      required String linksysToken,
      required String serialNumber}) {
    final endpoint = combineUrl(kTickets);
    Map<String, String> header = defaultHeader;
    header.addAll(
        {kHeaderLinksysToken: linksysToken, kHeaderSerialNumber: serialNumber});
    final body = createTicketInput.toJson();
    return this
        .post(Uri.parse(endpoint), body: jsonEncode(body), headers: header);
  }

  Future<Response> uploadToTicket(
      {required String ticketId,
      required String linksysToken,
      required String serialNumber,
      required String data}) {
    final endpoint =
        combineUrl(kCreateTicketUpload, args: {kTicketId: ticketId});
    Map<String, String> header = defaultHeader;
    header.addAll({
      kHeaderLinksysToken: linksysToken,
      kHeaderSerialNumber: serialNumber,
      'content-type': 'multipart/form-data'
    });
    final dataMultipart = MultipartFile.fromBytes(
      'jnap',
      data.codeUnits,
      filename: 'jnap.txt',
      contentType: MediaType('text', 'plain'),
    );
    return upload(Uri.parse(endpoint), [dataMultipart], headers: header);
  }

  Future<Response> getTickets({
    required String linksysToken,
    required String serialNumber,
  }) {
    final endpoint = combineUrl(kTickets);
    Map<String, String> header = defaultHeader;
    header.addAll({
      kHeaderLinksysToken: linksysToken,
      kHeaderSerialNumber: serialNumber,
    });
    return this.get(Uri.parse(endpoint), headers: header);
  }

  Future<Response> associateSmartDevice({
    required String linksysToken,
    required String serialNumber,
    required String fcmToken,
  }) {
    final endpoint = combineUrl(kSmartDeviceAssociate);
    Map<String, String> header = defaultHeader;

    header.addAll({
      kHeaderLinksysToken: linksysToken,
      kHeaderSerialNumber: serialNumber,
    });
    return this.post(Uri.parse(endpoint),
        headers: header, body: jsonEncode({'fcmToken': fcmToken}));
  }

  Future<Response> geolocation({
    required String linksysToken,
    required String serialNumber,
  }) {
    final endpoint = combineUrl(kGeoLocation);
    Map<String, String> header = defaultHeader;

    header.addAll({
      kHeaderLinksysToken: linksysToken,
      kHeaderSerialNumber: serialNumber,
      'cache-control': 'max-age=3600',
    });
    return this.get(
      Uri.parse(endpoint),
      headers: header,
    );
  }
}
