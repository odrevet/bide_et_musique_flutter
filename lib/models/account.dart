import 'song.dart';

class AccountLink {
  int id;
  String name;
  String image;

  AccountLink({this.id, this.name});
}

class Account extends AccountLink {
  String type;
  String inscription;
  String messageForum;
  String comments;
  String presentation;
  List<SongLink> favorites;
  List<Message> messages;
}

class Message {
  String recipient;
  String date;
  String body;
}
