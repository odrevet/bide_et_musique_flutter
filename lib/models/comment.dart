import 'package:bide_et_musique/models/song.dart';
import 'package:diacritic/diacritic.dart';

import 'session.dart';
import '../utils.dart';
import 'account.dart';

Future<void> sendEditComment(Song song, Comment comment, String text) async {
  if (text.isNotEmpty) {
    await Session.post('$baseUri/edit_comment.html?Comment__=${comment.id}',
        body: {
          'mode': 'Edit',
          'REF': song.link,
          'Comment__': comment.id.toString(),
          'Text': removeDiacritics(text),
        });
  }
}

Future<void> sendAddComment(Song song, String text) async {
  final url = song.link;
  if (text.isNotEmpty) {
    await Session.post(url, body: {
      'T': 'Song',
      'N': song.id.toString(),
      'Mode': 'AddComment',
      'Thread_': '',
      'Text': removeDiacritics(text),
      'x': '42',
      'y': '42'
    });
  }
}

class Comment {
  int? id;
  late AccountLink author;
  String? body;
  late String time;

  Comment();
}
