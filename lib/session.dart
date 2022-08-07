import 'dart:async';

import 'package:http/http.dart' as http;

import 'models/account.dart';

abstract class Session {
  static var accountLink = AccountLink();

  static Map<String, String> headers = {};

  static Future<http.Response> get(String url) async {
    http.Response response = await http.get(Uri.parse(url), headers: headers);
    _updateCookie(response);
    return response;
  }

  static Future<http.Response> post(String url, {body}) async {
    http.Response response = await http.post(Uri.parse(url), body: body, headers: headers);
    _updateCookie(response);
    return response;
  }

  static void _updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] = (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }
}
