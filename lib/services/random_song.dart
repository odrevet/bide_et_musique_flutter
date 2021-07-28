import 'dart:async';

import '../session.dart';
import '../utils.dart';

Future<int?> fetchRandomSongId() async {
  final url = '$baseUri/morceau-au-pif.html';
  final response = await Session.post(url);
  print(url);
  if (response.statusCode == 302) {
    String location = response.headers['location']!;
    return getIdFromUrl(location);
  } else {
    print(response.body);
    throw Exception(
        'Failed to fetch random song id : HTTP status code was ${response.statusCode}');
  }
}
