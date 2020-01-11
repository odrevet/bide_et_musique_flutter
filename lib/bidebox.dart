import 'package:flutter/material.dart';
import 'dart:async';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'account.dart';
import 'session.dart';
import 'utils.dart';

class Message {
  AccountLink from;
  String receivedCount;
  String sentCount;
}

String extractAccountLinkId(str) {
  final idRegex = RegExp(r'/bidebox_send.html\?T=(\d+)');
  var match = idRegex.firstMatch(str);
  if (match != null) {
    return match[1];
  } else {
    return null;
  }
}

Future<List<Message>> fetchMessages() async {
  List<Message> messages = [];

  String url = '$baseUri/bidebox_list.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var table = document.getElementsByClassName('bmtable')[0];

    var trs = table.children[0].children;
    trs.removeLast();
    trs.removeLast();
    for (var tr in trs) {
      var message = Message();
      String id = extractAccountLinkId(tr.children[0].children[0].attributes['href']);
      message.from = AccountLink(id: id, name: tr.children[0].text.trim());
      String secondTdText = tr.children[1].text.trim();
      print(secondTdText);
      
      message.receivedCount = '0';
      message.sentCount = '0';
      messages.add(message);
    }
  } else {
    throw Exception('Failed to load bideboxes');
  }

  return messages;
}

class BideBoxWidget extends StatelessWidget {
  final Future<List<Message>> messages;

  BideBoxWidget({Key key, this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Message>>(
        future: this.messages,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: Text('Ouille ouille ouille !')),
              body: Center(child: Center(child: errorDisplay(snapshot.error))),
            );
          }

          return CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Message> messages) {
    return ListView.builder(
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          Message message =  messages[index];
          return ListTile(
            title: Text(
              message.from.name,
            ),
            subtitle: Text('Envoyé: ${message.sentCount}, Reçu: ${message.receivedCount}'),
            leading: Icon(Icons.mail)
          );
        });
  }
}
