import '../utils.dart';
import 'account.dart';

class Forum {
  int id;
  String name;
  String subtitle;
  int nmsg;
  bool hasNew;
  String lastDate;
  AccountLink last;

  Forum({this.id, this.name, this.subtitle, this.nmsg, this.hasNew});

  Forum.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = stripTags(json['name']),
        subtitle = stripTags(json['subtitle']),
        nmsg = json['nmsg'],
        hasNew = json['has_new'],
        lastDate = json['last']['date'],
        last = AccountLink(id: json['last']['id'], name: json['last']['name']);
}

class ForumThread {
  int id;
  String title;
  int nbMsgs;
  bool pinned;
  bool resolved;
  bool hasPost;
  bool hasNew;
  bool read;
  int ownerId;
  String ownerName;
  String lastDate;
  AccountLink last;

  ForumThread(
      {this.id,
      this.title,
      this.nbMsgs,
      this.pinned,
      this.resolved,
      this.hasPost,
      this.hasNew,
      this.read,
      this.ownerId,
      this.ownerName,
      this.lastDate,
      this.last});

  ForumThread.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = stripTags(json['title']),
        nbMsgs = json['nb_msgs'],
        pinned = json['pinned'],
        resolved = json['resolved'],
        hasPost = json['has_post'],
        hasNew = json['new'],
        read = json['read'],
        ownerId = json['owner_id'],
        ownerName = json['owner_name'],
        lastDate = json['last']['date'],
        last = AccountLink(
            id: json['last']['user_id'], name: json['last']['user_name']);
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

  ForumMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = stripTags(json['title']),
        date = json['date'],
        text = json['text'],
        signature = json['signature'],
        folded = json['folded'],
        user = AccountLink(id: json['user']['id'], name: json['user']['name']);
}