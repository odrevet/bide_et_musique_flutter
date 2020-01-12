import 'package:flutter/material.dart';
import 'dart:async';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:diacritic/diacritic.dart';
import 'account.dart';
import 'session.dart';
import 'utils.dart';

class Exchange {
  AccountLink recipient;
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

Future<List<Exchange>> fetchMessages() async {
  List<Exchange> messages = [];

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
      var message = Exchange();
      String id =
          extractAccountLinkId(tr.children[0].children[0].attributes['href']);
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
  final Future<List<Exchange>> messages;
  final _newMessageController = TextEditingController();

  BideBoxWidget({Key key, this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Exchange>>(
        future: this.messages,
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
                          account: fetchAccount(message.recipient.id), defaultPage: 2,))),
              title: Text(
                message.recipient.name,
              ),
              subtitle: Text('${message.sentCount} ${message.receivedCount}'),
              leading: GestureDetector(
                  onTap: () {
                    _newMessageDialog(context, message.recipient);
                  },
                  child: Icon(Icons.mail)));
        });
  }

  _sendMessage(id) async {
    String message = removeDiacritics(_newMessageController.text);
    final url = '$baseUri/bidebox_send.html';

    if (message.isNotEmpty) {
      await Session.post(url,
          body: {'Message': message, 'T': id, 'R': '', 'M': 'S'});
    }
  }

  _newMessageDialog(BuildContext context, AccountLink to) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Message pour ${to.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                    maxLines: 5,
                    controller: _newMessageController,
                    decoration: InputDecoration(
                      hintText: 'Entrez votre message ici',
                    )),
                RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                    child: Text(
                      'Envoyer',
                    ),
                    onPressed: () async {
                      await _sendMessage(to.id);
                      _newMessageController.text = '';
                      Navigator.of(context).pop();
                    },
                    color: Colors.orangeAccent),
              ],
            ),
          ),
        );
      },
    );
  }
}
