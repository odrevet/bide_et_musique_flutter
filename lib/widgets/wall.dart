import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/song.dart';
import '../services/account.dart';
import '../services/song.dart';
import '../services/wall.dart';
import '../session.dart';
import '../utils.dart';
import 'account.dart';
import 'htmlDefault.dart';
import 'song.dart';

class WallWidget extends StatefulWidget {
  WallWidget({Key key}) : super(key: key);

  @override
  _WallWidgetState createState() => _WallWidgetState();
}

class _WallWidgetState extends State<WallWidget> {
  Future<List<Post>> posts;
  final _newMessageController = TextEditingController();

  @override
  void initState() {
    _updatePosts();
    super.initState();
  }

  _updatePosts() async {
    setState(() {
      posts = fetchPosts();
    });
  }

  _newMessageDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          actions: <Widget>[
            RaisedButton.icon(
              icon: Icon(Icons.send),
              label: Text("Envoyer"),
              onPressed: () async {
                await sendMessage(_newMessageController.text);
                _updatePosts();
                _newMessageController.text = '';
                Navigator.of(context).pop();
              },
            )
          ],
          title: Text('Nouveau message'),
          content: TextFormField(
              maxLines: 5,
              controller: _newMessageController,
              decoration: InputDecoration(
                hintText: 'Entrez votre message ici',
              )),
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
            child: Icon(Icons.add_comment),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text('Quoi de neuf ?'),
      ),
      floatingActionButton: postNew,
      body: Center(
        child: FutureBuilder<List<Post>>(
          future: this.posts,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
            } else if (snapshot.hasError) {
              return ErrorDisplay(snapshot.error);
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Post> posts) {
    var rows = <Widget>[];
    for (Post post in posts) {
      rows.add(Card(
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.black,
                  ),
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
                      text: post.during.name,
                      style: linkStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SongPageWidget(
                                    songLink: SongLink(
                                        id: post.during.id,
                                        name: post.during.name),
                                    song: fetchSong(post.during.id)))),
                    ),
                  ]),
            ),
            Divider(),
            HtmlDefault(
              data: post.body,
            )
          ],
        ),
      ));
    }

    return ListView(children: rows);
  }
}
