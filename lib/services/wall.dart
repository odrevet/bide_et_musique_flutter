import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/account.dart';
import '../models/post.dart';
import '../models/song.dart';
import '../session.dart';
import '../utils.dart';

Future<List<Post>> fetchPosts() async {
  var posts = <Post>[];
  final url = '$baseUri/mur-des-messages.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    dom.Element wall = document.getElementById('mur')!;
    for (dom.Element msg in wall.getElementsByClassName('murmsg')) {
      String body = msg.getElementsByClassName('corpsmsg')[0].innerHtml;

      var basmsg = msg.getElementsByClassName('basmsg')[0];

      var accountA = basmsg.getElementsByTagName('a')[0];
      var accountHref = accountA.attributes['href']!;

      var idAccount = getIdFromUrl(accountHref);
      var accountLink =
          AccountLink(id: idAccount, name: stripTags(accountA.innerHtml));

      String? time = '';
      var links = basmsg.children[0].getElementsByTagName('a');

      if (links.length > 0) {
        var artistLink = links[0];
        var title = links[1];

        final idRegex = RegExp(r'(le \d+/\d+/\d+ à \d+:\d+:\d+)');
        var match = idRegex.firstMatch(basmsg.innerHtml);

        if (match != null) {
          time = match[1];
        }

        var songLink = SongLink(
            id: getIdFromUrl(title.attributes['href']!)!,
            name: stripTags(title.innerHtml),
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
  final url = '$baseUri/mur-des-messages.html';

  if (message.isNotEmpty) {
    await Session.post(url, body: {'T': message, 'Type': '2'});
  }
}
