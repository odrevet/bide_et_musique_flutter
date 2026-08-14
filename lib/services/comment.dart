import 'package:diacritic/diacritic.dart';

import '../models/song.dart';
import '../models/session.dart';
import '../models/comment.dart';
import '../utils.dart';

Future<void> sendAddComment(Song song, String text) async {
  final url = song.link;
  if (text.isNotEmpty) {
    await Session.post(
      url,
      body: {
        'T': 'Song',
        'N': song.id.toString(),
        'Mode': 'AddComment',
        'Thread_': '',
        'Text': removeDiacritics(text),
        'x': '42',
        'y': '42',
      },
    );
  }
}

Future<void> sendEditComment(Song song, Comment comment, String text) async {
  if (text.isNotEmpty) {
    await Session.post(
      '$baseUri/edit_comment.html?Comment__=${comment.id}',
      body: {
        'mode': 'Edit',
        'REF': song.link,
        'Comment__': comment.id.toString(),
        'Text': removeDiacritics(text),
      },
    );
  }
}
