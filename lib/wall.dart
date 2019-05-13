import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:flutter_html/flutter_html.dart';
import 'utils.dart';
import 'song.dart';
import 'account.dart';

Future<List<Post>> fetchPosts() async {
  var posts = <Post>[];
  final url = '$baseUri/mur-des-messages.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    dom.Element wall = document.getElementById('mur');
    for (dom.Element msg in wall.getElementsByClassName('murmsg')) {
      var post = Post();
      post.body =
          msg.getElementsByClassName('corpsmsg')[0].innerHtml;

      var basmsg = msg.getElementsByClassName('basmsg')[0];

      var accountLink = basmsg.children[0].children[0];
      var accountHref = accountLink.attributes['href'];

      var id = extractAccountId(accountHref);
      var account = Account(id, stripTags(accountLink.innerHtml));

      post.author = account;

      var song = Song();
      var artistLink = basmsg.children[0].children[1];
      song.artist = artistLink.innerHtml;

      var songLink = basmsg.children[0].children[2];
      song.title = stripTags(songLink.innerHtml);

      post.during = song;

      posts.add(post);
    }
    return posts;
  } else {
    throw Exception('Failed to load post');
  }
}

class Post {
  Account author;
  Song during;
  String body;
  String date;
  String time;
  Post();
}

class WallWidget extends StatelessWidget {
  final Future<List<Post>> posts;
  final _font = const TextStyle(fontSize: 18.0);

  WallWidget({Key key, this.posts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quoi de neuf ?'),
      ),
      body: Center(
        child: FutureBuilder<List<Post>>(
          future: posts,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Post> posts) {
    var rows = <ListTile>[];
    for (Post post in posts) {
      rows.add(ListTile(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AccountPageWidget(
                        account: post.author,
                        accountInformations:
                            fetchAccountInformations(post.author.id))));
          },
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Image(
                image: NetworkImage(
                    '$baseUri/images/avatars/${post.author.id}.jpg')),
          ),
          title: Html(
              data: post.body,
              //style: _font,
              onLinkTap: (url) {
                onLinkTap(url);
              }),
          subtitle: Text(
              'Par ' + post.author.name + ' pendant ' + post.during.title)));
    }

    return ListView(children: rows);
  }
}

