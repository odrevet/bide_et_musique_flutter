import 'package:http/http.dart' as http;

import 'account.dart';

class Session {
  Session._();

  static var accountLink = AccountLink();

  static final Map<String, String> _baseHeaders = {};

  static Map<String, String> get headers => Map.unmodifiable(_baseHeaders);

  static void setHeader(String key, String value) {
    _baseHeaders[key] = value;
  }

  static void removeHeader(String key) {
    _baseHeaders.remove(key);
  }

  static void clearHeaders() {
    _baseHeaders.clear();
  }

  static Future<http.Response> get(String url) async {
    http.Response response = await http.get(
      Uri.parse(url),
      headers: _baseHeaders,
    );
    _updateCookie(response);
    return response;
  }

  static Future<http.Response> post(String url, {body}) async {
    http.Response response = await http.post(
      Uri.parse(url),
      body: body,
      headers: _baseHeaders,
    );
    _updateCookie(response);
    return response;
  }

  static void _updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      _baseHeaders['cookie'] = (index == -1)
          ? rawCookie
          : rawCookie.substring(0, index);
    }
  }
}
