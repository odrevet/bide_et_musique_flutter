import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'account.dart';
import 'session.dart';
import 'utils.dart';

class Forum {
  int id;
  String name;
  String subtitle;
  int nmsg;
  bool hasNew;
  AccountLink last;

  Forum({this.id, this.name, this.subtitle, this.nmsg, this.hasNew});

  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
        id: json['id'],
        name: stripTags(json['name']),
        subtitle: stripTags(json['subtitle']),
        nmsg: json['nmsg'],
        hasNew: json['has_new']);
  }
}

Future<List<Forum>> fetchForums() async {
  List<Forum> forums = [];
  final url = '$baseUri/forums/';
  final responseJson = await Session.get(url);

  if (responseJson.statusCode == 200) {
    try {
      String decodedString = utf8.decode(responseJson.bodyBytes);
      Map<String, dynamic> decodedJson = json.decode(decodedString);

      for (var forum in decodedJson['forums']) {
        forums.add(Forum.fromJson(forum));
      }
    } catch (e) {
      print('ERROR $e');
    }
  } else {
    print('Response was ${responseJson.statusCode}');
  }

  return forums;
}

class ForumThread {
  int id;
  String title;
  int nbMsgs;
  bool pinned;
  bool resolved;
  bool hasPost;
  bool isNew;
  bool read;
  int ownerId;
  String ownerName;
  AccountLink last;

  ForumThread(
      {this.id,
      this.title,
      this.nbMsgs,
      this.pinned,
      this.resolved,
      this.hasPost,
      this.isNew,
      this.read,
      this.ownerId,
      this.ownerName});

  factory ForumThread.fromJson(Map<String, dynamic> json) {
    return ForumThread(
        id: json['id'],
        title: stripTags(json['title']),
        nbMsgs: json['nbMsgs'],
        pinned: json['pinned'],
        resolved: json['resolved'],
        hasPost: json['has_post'],
        isNew: json['new'],
        read: json['read'],
        ownerId: json['owner_id'],
        ownerName: json['owner_name']);
  }
}

Future<List<ForumThread>> fetchForumThreads(forumId) async {
  List<ForumThread> forumThreads = [];
  final url = '$baseUri/forums/$forumId';
  final responseJson = await Session.get(url);

  if (responseJson.statusCode == 200) {
    try {
      String decodedString = utf8.decode(responseJson.bodyBytes);
      Map<String, dynamic> decodedJson = json.decode(decodedString);

      for (var forumThread in decodedJson['threads']) {
        forumThreads.add(ForumThread.fromJson(forumThread));
      }
    } catch (e) {
      print('ERROR $e');
    }
  } else {
    print('Response was ${responseJson.statusCode}');
  }

  return forumThreads;
}

// forums/[forum_id]/thread/[thread_id]
class ForumMessage {}

class ForumWidget extends StatefulWidget {
  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Les forums'),
        ),
        body: FutureBuilder<List<Forum>>(
            future: fetchForums(),
            builder: (context, snapshot) {
              var forum = snapshot.data;
              return ListView.builder(
                  itemCount: forum.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(
                        forum[index].name,
                      ),
                      subtitle: Text(forum[index].subtitle),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ForumThreadWidget(fetchForumThreads(forum[index].id))));
                        }
                    );
                  });
            }));
  }
}


class ForumThreadWidget extends StatefulWidget {
  Future<List<ForumThread>>  _forumThreads;

  ForumThreadWidget(this._forumThreads);

  @override
  _ForumThreadWidgetState createState() => _ForumThreadWidgetState();
}

class _ForumThreadWidgetState extends State<ForumThreadWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Liste des discutions'),
        ),
        body: FutureBuilder<List<ForumThread>>(
            future: this.widget._forumThreads,
            builder: (context, snapshot) {
              var forumThread = snapshot.data;
              return ListView.builder(
                  itemCount: forumThread.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        title: Text(
                          forumThread[index].title,
                        ),
                      trailing: forumThread[index].isNew ? Icon(Icons.fiber_new) : null,
                        /*onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ForumThreadWidget(fetchForumThreads(forum[index].id))));
                        }*/
                    );
                  });
            }));
  }
}
