import 'dart:async';

import 'package:http/http.dart' as http;

import 'account.dart';

abstract class Session {
  static var accountLink = AccountLink();

  static Map<String, String> headers = {};

  static Future<http.Response> get(String url) async {
    http.Response response = await http.get(url, headers: headers);
    updateCookie(response);
    return response;
  }

  static Future<http.Response> post(String url, {body}) async {
    http.Response response = await http.post(url, body: body, headers: headers);
    updateCookie(response);
    return response;
  }

  static void updateCookie(http.Response response) {
    String rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }
}
