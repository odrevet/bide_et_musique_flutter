import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import 'account.dart';
import 'session.dart';
import 'utils.dart';

class Exchange {
  AccountLink recipient;
  String receivedCount;
  String sentCount;
}

int getAccountIdFromUrl(str) {
  final idRegex = RegExp(r'/bidebox_send.html\?T=(\d+)');
  var match = idRegex.firstMatch(str);
  if (match != null) {
    return int.parse(match[1]);
  } else {
    return null;
  }
}

Future<List<Exchange>> fetchExchanges() async {
  List<Exchange> messages = [];

  String url = '$baseUri/bidebox_list.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    if (tables.isEmpty) {
      return messages;
    }

    dom.Element table = tables[0];
    var trs = table.children[0].children;
    trs.removeLast();
    trs.removeLast();
    for (var tr in trs) {
      var message = Exchange();
      int id =
          getAccountIdFromUrl(tr.children[0].children[0].attributes['href']);
      message.recipient = AccountLink(id: id, name: tr.children[0].text.trim());
      List<String> secondTdText = tr.children[1].text.split('\n');
      message.sentCount = secondTdText[2].trim();
      message.receivedCount = secondTdText[3].trim();
      messages.add(message);
    }
  } else {
    throw Exception('Failed to load bideboxes');
  }

  return messages;
}

class BideBoxWidget extends StatelessWidget {
  final Future<List<Exchange>> exchanges;

  BideBoxWidget({Key key, this.exchanges}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Exchange>>(
        future: this.exchanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Center(
              child: errorDisplay(snapshot.error),
            );
          }

          return CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Exchange> messages) {
    return ListView.builder(
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          Exchange message = messages[index];
          return ListTile(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AccountPageWidget(
                            account: fetchAccount(message.recipient.id),
                            defaultPage: 2,
                          ))),
              title: Text(
                message.recipient.name,
              ),
              subtitle: Text('${message.sentCount} ${message.receivedCount}'),
              leading: GestureDetector(
                  onTap: () => showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            MessageEditor(message.recipient),
                      ),
                  child: Icon(Icons.mail)));
        });
  }
}

class MessageEditor extends StatefulWidget {
  final AccountLink _accountLink;

  MessageEditor(this._accountLink);

  @override
  _MessageEditorState createState() => _MessageEditorState();
}

class _MessageEditorState extends State<MessageEditor> {
  final _newMessageController = TextEditingController();

  Future<bool>_sendMessage() async {
    String message = removeDiacritics(_newMessageController.text);
    final url = '$baseUri/bidebox_send.html';

    if (message.isNotEmpty) {
      var response = await Session.post(url, body: {
        'Message': message,
        'T': widget._accountLink.id.toString(),
        'R': '',
        'M': 'S'
      });
      return response.statusCode == 200;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      actions: [
        RaisedButton.icon(
          icon: Icon(Icons.send),
          label: Text("Envoyer"),
          onPressed: () async {
            bool status = await _sendMessage();
            Navigator.of(context).pop(status);
          },
        )
      ],
      title: Text('Message pour ${widget._accountLink.name}'),
      content: TextFormField(
          maxLength: 500,
          maxLines: 5,
          controller: _newMessageController,
          decoration: InputDecoration(
            hintText: 'Entrez votre message ici',
          )),
    );
  }
}
