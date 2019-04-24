import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'account.dart';
import 'utils.dart';

Future<Map<String, Account>> fetchTrombidoscope() async {
  var accounts = <String, Account>{};

  final url = '$baseUri/trombidoscope.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var table = document.getElementsByClassName('bmtable')[0];
    for (dom.Element td in table.getElementsByTagName('td')) {
      var a = td.children[0];
      var href = a.attributes['href'];
      var id = extractAccountId(href);
      var account = Account(id, stripTags(a.innerHtml));
      accounts[a.children[0].attributes['src']] = account;
    }
    return accounts;
  } else {
    throw Exception('Failed to load trombines');
  }
}

class TrombidoscopeWidget extends StatelessWidget {
  final Future<Map<String, Account>> accounts;  // [avatar : account]
  final _font = TextStyle(
      fontSize: 18.0,
      background: Paint()..color = Color.fromARGB(180, 150, 150, 100));

  TrombidoscopeWidget({Key key, this.accounts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Le trombidoscope'),
      ),
      body: Center(
        child: FutureBuilder<Map<String, Account>>(
          future: accounts,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
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

  Widget _buildView(BuildContext context, Map<String, Account> accounts) {
    var rows = <GestureDetector>[];

    accounts.forEach((img, account) {
      var url = baseUri + img;
      rows.add(GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new AccountPageWidget(
                      account: account,
                      accountInformations: fetchAccountInformations(account.id))));
        },
        child: Container(
          child: Text(account.name, style: _font),
          decoration: new BoxDecoration(
              color: Colors.orangeAccent,
              image: new DecorationImage(
                fit: BoxFit.contain,
                alignment: FractionalOffset.topCenter,
                image: new NetworkImage(url),
              )),
        ),
      ));

    });

    return GridView.count(crossAxisCount: 2, children: rows);
  }
}
