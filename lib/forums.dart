import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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

class ForumMessage {
  int id;
  String title;
  String date;
  String text;
  String signature;
  bool folded;
  AccountLink user;

  ForumMessage(
      {this.id,
      this.title,
      this.date,
      this.text,
      this.signature,
      this.folded,
      this.user});

  factory ForumMessage.fromJson(Map<String, dynamic> json) {
    return ForumMessage(
        id: json['id'],
        title: stripTags(json['title']),
        date: json['date'],
        text: json['text'],
        signature: json['signature'],
        folded: json['folded'],
        user: AccountLink(id: json['user']['id'].toString(), name: json['user']['name']));
  }
}

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
                                  builder: (context) => ForumThreadWidget(
                                      forum[index],
                                      fetchForumThreads(forum[index].id))));
                        });
                  });
            }));
  }
}

class ForumThreadWidget extends StatefulWidget {
  Future<List<ForumThread>> _forumThreads;
  final Forum _forum;

  ForumThreadWidget(this._forum, this._forumThreads);

  @override
  _ForumThreadWidgetState createState() => _ForumThreadWidgetState();
}

class _ForumThreadWidgetState extends State<ForumThreadWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget._forum.name),
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
                        trailing: forumThread[index].isNew
                            ? Icon(Icons.fiber_new)
                            : null,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ForumMessagesWidget(
                                      fetchForumMessages(widget._forum.id,
                                          forumThread[index].id))));
                        });
                  });
            }));
  }
}

Future<List<ForumMessage>> fetchForumMessages(forumId, threadId) async {
  List<ForumMessage> forumMessages = [];
  final url = '$baseUri/forums/$forumId/thread/$threadId';
  final responseJson = await Session.get(url);

  if (responseJson.statusCode == 200) {
    try {
      String decodedString = utf8.decode(responseJson.bodyBytes);
      Map<String, dynamic> decodedJson = json.decode(decodedString);

      for (var forumMessage in decodedJson['messages']) {
        forumMessages.add(ForumMessage.fromJson(forumMessage));
      }
    } catch (e) {
      print('ERROR $e');
    }
  } else {
    print('Response was ${responseJson.statusCode}');
  }

  return forumMessages;
}

class ForumMessagesWidget extends StatefulWidget {
  Future<List<ForumMessage>> _forumMessages;

  ForumMessagesWidget(this._forumMessages);

  @override
  _ForumMessagesWidgetState createState() => _ForumMessagesWidgetState();
}

class _ForumMessagesWidgetState extends State<ForumMessagesWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Messages"),
        ),
        body: FutureBuilder<List<ForumMessage>>(
            future: this.widget._forumMessages,
            builder: (context, snapshot) {
              var forumMessages = snapshot.data;
              return ListView.separated(
                  separatorBuilder: (context, index) => Divider(),
                  itemCount: forumMessages.length,
                  itemBuilder: (BuildContext context, int index) {
                    ForumMessage forumMessage = forumMessages[index];
                    return ListTile(
                        title: Html(
                          data: forumMessage.text,
                        ),
                        subtitle: Text(
                            '${forumMessage.date} par ${forumMessage.user.name}'));
                  });
            }));
  }
}
