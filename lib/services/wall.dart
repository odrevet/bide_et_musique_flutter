import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../session.dart';
import '../utils.dart';

import '../models/post.dart';
import '../models/song.dart';
import '../models/account.dart';

Future<List<Post>> fetchPosts() async {
  var posts = <Post>[];
  final url = '$baseUri/mur-des-messages.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    dom.Element wall = document.getElementById('mur');
    for (dom.Element msg in wall.getElementsByClassName('murmsg')) {
      var post = Post();
      post.body = msg.getElementsByClassName('corpsmsg')[0].innerHtml;

      var basmsg = msg.getElementsByClassName('basmsg')[0];

      var accountA = basmsg.children[0].children[0];
      var accountHref = accountA.attributes['href'];

      var idAccount = getIdFromUrl(accountHref);
      var accountLink =
          AccountLink(id: idAccount, name: stripTags(accountA.innerHtml));

      post.author = accountLink;

      var songLink = SongLink();
      var artistLink = basmsg.children[0].children[1];
      songLink.artist = artistLink.innerHtml;

      var title = basmsg.children[0].children[2];
      songLink.name = stripTags(title.innerHtml);
      songLink.id = getIdFromUrl(title.attributes['href']);
      post.during = songLink;

      final idRegex = RegExp(r'(le \d+/\d+/\d+ à \d+:\d+:\d+)');
      var match = idRegex.firstMatch(basmsg.innerHtml);
      if (match != null) {
        post.time = match[1];
      } else {
        post.time = '';
      }

      posts.add(post);
    }
    return posts;
  } else {
    throw Exception('Failed to load post');
  }
}
