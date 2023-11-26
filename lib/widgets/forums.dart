import 'dart:async';

import 'package:flutter/material.dart';

import '../models/forum.dart';
import '../services/forum.dart';
import '../widgets/error_display.dart';
import 'html_with_style.dart';

class ForumWidget extends StatefulWidget {
  const ForumWidget({super.key});

  @override
  State<ForumWidget> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Les forums'),
        ),
        body: FutureBuilder<List<Forum>>(
            future: fetchForums(),
            builder: (context, snapshot) {
              var forums = snapshot.data;
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: forums!.length,
                    itemBuilder: (BuildContext context, int index) {
                      Forum forum = forums[index];
                      return ListTile(
                          title: Text(
                            forum.name!,
                          ),
                          subtitle: Text(forum.subtitle!),
                          trailing: forum.hasNew!
                              ? const Icon(Icons.fiber_new)
                              : null,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForumThreadWidget(
                                        forum, fetchForumThreads(forum.id))));
                          });
                    });
              } else if (snapshot.hasError) {
                return Center(child: ErrorDisplay(snapshot.error));
              }

              return const Center(child: CircularProgressIndicator());
            }));
  }
}

class ForumThreadWidget extends StatefulWidget {
  final Future<List<ForumThread>> _forumThreads;
  final Forum _forum;

  const ForumThreadWidget(this._forum, this._forumThreads, {super.key});

  @override
  State<ForumThreadWidget> createState() => _ForumThreadWidgetState();
}

class _ForumThreadWidgetState extends State<ForumThreadWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget._forum.name!),
        ),
        body: FutureBuilder<List<ForumThread>>(
            future: widget._forumThreads,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<ForumThread> forumThreads = snapshot.data!;
                return ListView.builder(
                    itemCount: forumThreads.length,
                    itemBuilder: (BuildContext context, int index) {
                      ForumThread forumThread = forumThreads[index];
                      String messageCountText =
                          forumThread.nbMsgs! > 1 ? 'messages' : 'message';
                      return ListTile(
                          title: Text(
                            forumThread.title!,
                          ),
                          subtitle: Text(
                              '${forumThread.nbMsgs} $messageCountText, dernier par ${forumThread.last!.name} ${forumThread.lastDate}'),
                          trailing: forumThread.hasNew!
                              ? const Icon(Icons.fiber_new)
                              : null,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForumMessagesWidget(
                                        forumThread,
                                        fetchForumMessages(widget._forum.id,
                                            forumThread.id))));
                          });
                    });
              } else if (snapshot.hasError) {
                return Center(child: ErrorDisplay(snapshot.error));
              }

              return const Center(child: CircularProgressIndicator());
            }));
  }
}

class ForumMessagesWidget extends StatefulWidget {
  final ForumThread _forumThread;
  final Future<List<ForumMessage>> _forumMessages;

  const ForumMessagesWidget(this._forumThread, this._forumMessages, {super.key});

  @override
  State<ForumMessagesWidget> createState() => _ForumMessagesWidgetState();
}

class _ForumMessagesWidgetState extends State<ForumMessagesWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget._forumThread.title!),
        ),
        body: FutureBuilder<List<ForumMessage>>(
            future: widget._forumMessages,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var forumMessages = snapshot.data!;
                return ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: forumMessages.length,
                    itemBuilder: (BuildContext context, int index) {
                      ForumMessage forumMessage = forumMessages[index];
                      return ListTile(
                          title: HtmlWithStyle(data: forumMessage.text),
                          subtitle: Text(
                              '${forumMessage.date} par ${forumMessage.user?.name}'));
                    });
              } else if (snapshot.hasError) {
                return Center(child: ErrorDisplay(snapshot.error));
              }

              return const Center(child: CircularProgressIndicator());
            }));
  }
}
