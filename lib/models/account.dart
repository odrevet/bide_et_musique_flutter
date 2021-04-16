import 'song.dart';

class AccountLink {
  int? id;
  String? name;
  String? image;

  AccountLink({this.id, this.name});
}

class Account extends AccountLink {
  late String type;
  late String inscription;
  late String messageForum;
  late String comments;
  String? presentation;
  List<SongLink>? favorites;
  List<Message>? messages;
}

class Message {
  String? recipient;
  String? date;
  late String body;
}
