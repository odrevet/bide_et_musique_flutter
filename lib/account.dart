import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'utils.dart';

class Account {
  String id;
  String name;

  Account(this.id, this.name);
}

Future<String> fetchAccount(String accountId) async {
  final url = 'http://www.bide-et-musique.com/account/' + accountId + '.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var txtpresentation = document.getElementsByClassName('txtpresentation')[0].innerHtml;
    return stripTags(txtpresentation);
  } else {
    throw Exception('Failed to load account ');
  }
}

class AccountPageWidget extends StatelessWidget {
  Account account;
  Future<String> txtpresentation;

  AccountPageWidget({Key key, this.account, this.txtpresentation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: txtpresentation,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(snapshot.data);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(String txtpresentation) {
    return new Container(child: Text(txtpresentation));
  }
}