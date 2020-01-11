import 'package:flutter/material.dart';
import 'dart:async';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'account.dart';
import 'session.dart';
import 'utils.dart';

class Message{
  AccountLink from;
  int receivedCount = 0;
  int sentCount = 0;
}

Future<List <Message>>fetchMessages() async {
  List <Message> messages = [];

  String url = '$baseUri/bidebox_list.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var table = document.getElementsByClassName('bmtable')[0];

    var trs = table.children[0].children;
    trs.removeAt(0); //remove header
    for (var tr in trs) {
      print(tr.toString());
    }
  } else {
    throw Exception('Failed to load votes');
  }

  return messages;
}

class BideBoxWidget extends StatelessWidget {
  final Future<List<Message>> messages;

  BideBoxWidget({Key key, this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(child:Text('TODOBIDEBOX'));
  }
}
