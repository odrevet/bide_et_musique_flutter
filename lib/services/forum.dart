import 'dart:convert';

import '../models/forum.dart';
import '../session.dart';
import '../utils.dart';

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
      forumMessages.add(ForumMessage(title: 'Erreur JSON', text: e.toString()));
    }
  } else {
    forumMessages.add(ForumMessage(
        title: 'Erreur HTTP', text: 'Code ${responseJson.statusCode}'));
  }

  return forumMessages;
}
