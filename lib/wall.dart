import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'account.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

class Post {
  AccountLink author;
  SongLink during;
  String body;
  String date;
  String time;

  Post();
}

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

      var idAccount = extractAccountId(accountHref);
      var accountLink =
          AccountLink(id: idAccount, name: stripTags(accountA.innerHtml));

      post.author = accountLink;

      var songLink = SongLink();
      var artistLink = basmsg.children[0].children[1];
      songLink.artist = artistLink.innerHtml;

      var title = basmsg.children[0].children[2];
      songLink.title = stripTags(title.innerHtml);
      songLink.id = extractSongId(title.attributes['href']);
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

class WallWidget extends StatelessWidget {
  final Future<List<Post>> posts;
  final _newMessageController = TextEditingController();

  WallWidget({Key key, this.posts}) : super(key: key);

  void _sendMessage() async {
    String message = _newMessageController.text;
    final url = '$baseUri/mur-des-messages.html';

    if (message.isNotEmpty) {
      await Session.post(url, body: {'T': message, 'Type': '2'});
    }
  }

  _newMessageDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nouveau message'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                    maxLines : 5,
                    controller: _newMessageController,
                    decoration: InputDecoration(
                      hintText: 'entrez votre message ici',
                    )),
                RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                    child: Text(
                      'Envoyer',
                    ),
                    onPressed: () {
                      _sendMessage();
                      Navigator.of(context).pop();
                    },
                    color: Colors.orangeAccent),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var postNew = Session.accountLink.id == null
        ? null
        : FloatingActionButton(
            onPressed: () {
              _newMessageDialog(context);
            },
            child: Icon(Icons.add),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text('Quoi de neuf ?'),
      ),
      floatingActionButton: postNew,
      body: Center(
        child: FutureBuilder<List<Post>>(
          future: posts,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
            } else if (snapshot.hasError) {
              return errorDisplay(snapshot.error);
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Post> posts) {
    var linkStyle = TextStyle(
      fontSize: 14.0,
      color: Colors.blue,
    );

    var rows = <Widget>[];
    for (Post post in posts) {
      rows.add(ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Image(
                image: NetworkImage(
                    '$baseUri/images/avatars/${post.author.id}.jpg')),
          ),
          title: Html(
              data: post.body,
              onLinkTap: (url) {
                onLinkTap(url, context);
              }),
          subtitle: RichText(
            text: TextSpan(
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.black,
                ),
                text: 'Par ',
                children: [
                  TextSpan(
                    text: post.author.name,
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AccountPageWidget(
                                  account: fetchAccount(post.author.id)))),
                  ),
                  TextSpan(
                    text: ' ${post.time} pendant ',
                  ),
                  TextSpan(
                    text: post.during.title,
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SongPageWidget(
                                  songLink: SongLink(
                                      id: post.during.id,
                                      title: post.during.title),
                                  song: fetchSong(post.during.id)))),
                  ),
                ]),
          )));
      rows.add(Divider());
    }

    return ListView(children: rows);
  }
}
