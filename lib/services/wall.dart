import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/account.dart';
import '../models/post.dart';
import '../models/song.dart';
import '../models/session.dart';
import '../utils.dart';

Future<List<Post>> fetchPosts() async {
  var posts = <Post>[];
  const url = '$baseUri/mur-des-messages.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    dom.Element wall = document.getElementById('mur')!;
    for (dom.Element msg in wall.getElementsByClassName('murmsg')) {
      String body = msg.getElementsByClassName('corpsmsg')[0].innerHtml;

      var basmsg = msg.getElementsByClassName('basmsg')[0];
      String? time = '';

      var links = basmsg.children[0].getElementsByTagName('a');

      if (links.isNotEmpty) {
        var accountA = links[0];
        var accountHref = accountA.attributes['href']!;

        var idAccount = getIdFromUrl(accountHref);
        var accountLink = AccountLink(id: idAccount, name: accountA.text);

        var artistLink = links[1];
        var title = links[2];

        final idRegex = RegExp(r'(le \d+/\d+/\d+ à \d+:\d+:\d+)');
        var match = idRegex.firstMatch(basmsg.text);

        if (match != null) {
          time = match[1];
        }

        var songLink = SongLink(
            id: getIdFromUrl(title.attributes['href']!)!,
            name: title.text,
            artist: artistLink.innerHtml);
        var post = Post(accountLink, songLink, body, '', time);
        posts.add(post);
      }
    }
    return posts;
  } else {
    throw Exception('Failed to load post');
  }
}

Future<void> sendMessage(String message) async {
  const url = '$baseUri/mur-des-messages.html';

  if (message.isNotEmpty) {
    await Session.post(url, body: {'T': message, 'Type': '2'});
  }
}
