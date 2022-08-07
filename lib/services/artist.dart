import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/artist.dart';
import '../session.dart';
import '../utils.dart';

Future<Artist?> fetchArtist(int? artistId) async {
  Artist? artist;
  final url = '$baseUri/artist/$artistId';

  final responseJson = await Session.get(url);

  if (responseJson.statusCode == 200) {
    try {
      artist = Artist.fromJson(json.decode(utf8.decode(responseJson.bodyBytes)));
    } catch (e) {
      if (kDebugMode) {
        print('Error while decoding artist : $e');
      }
    }
  } else {
    throw Exception('Failed to load artist with id $artistId');
  }

  return artist;
}
