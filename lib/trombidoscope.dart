import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'account.dart';
import 'utils.dart';

Future<List<Account>> fetchTrombidoscope() async {
  var accounts = <Account>[];
  final url = 'http://www.bide-et-musique.com/trombidoscope.html';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var table = document.getElementsByClassName('bmtable')[0];
    for (dom.Element td in table.getElementsByTagName('td')) {
      var href = td.children[0].attributes['href'];
      final idRegex = RegExp(r'/account/(\d+).html');
      var match = idRegex.firstMatch(href);
      var account = Account(match[1]);
      account.name = stripTags(td.children[0].innerHtml);
      accounts.add(account);
    }
    return accounts;
  } else {
    throw Exception('Failed to load trombines');
  }
}

class TrombidoscopeWidget extends StatelessWidget {
  final Future<List<Account>> accounts;
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
        child: FutureBuilder<List<Account>>(
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

  Widget _buildView(BuildContext context, List<Account> accounts) {
    var rows = <GestureDetector>[];
    for (Account account in accounts) {
      var url = 'http://www.bide-et-musique.com/images/photos/ACT' +
          account.id +
          '.jpg';
      rows.add(
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new AccountPageWidget(account: account, txtpresentation: fetchAccount(account.id))));
                  },
                  child:  Container(
                    child: Text(account.name, style: _font),
                    decoration: new BoxDecoration(
                        color: Colors.orangeAccent,
                        image: new DecorationImage(
                          fit: BoxFit.contain,
                          alignment: FractionalOffset.topCenter,
                          image: new NetworkImage(url),
                        )),
                  ),
              )



      );
    }

    return GridView.count(crossAxisCount: 2, children: rows);
  }
}
