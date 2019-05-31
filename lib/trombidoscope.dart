import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'account.dart';
import 'utils.dart';

Future<Map<String, AccountLink>> fetchTrombidoscope() async {
  var accounts = <String, AccountLink>{};

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
      var account = AccountLink(id: id, name: stripTags(a.innerHtml));
      accounts[a.children[0].attributes['src']] = account;
    }
    return accounts;
  } else {
    throw Exception('Failed to load trombines');
  }
}

class TrombidoscopeWidget extends StatefulWidget {
  TrombidoscopeWidget({Key key}) : super(key: key);

  @override
  _TrombidoscopeWidgetState createState() => _TrombidoscopeWidgetState();
}

class _TrombidoscopeWidgetState extends State<TrombidoscopeWidget> {
  Future<Map<String, AccountLink>> _avatarAccountLink; // [avatar : account]

  final _font = TextStyle(
      fontSize: 18.0,
      background: Paint()..color = Color.fromARGB(180, 150, 150, 100));

  @override
  void initState() {
    super.initState();
    _avatarAccountLink = fetchTrombidoscope();

  }

  @override
  Widget build(BuildContext context) {
    var refreshButton = IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () {
          this.setState(() {
            _avatarAccountLink = fetchTrombidoscope();
          });
        });

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Text('Le trombidoscope'), refreshButton]),
      ),
      body: Center(
        child: FutureBuilder<Map<String, AccountLink>>(
          future: _avatarAccountLink,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
            } else if (snapshot.hasError) {
              return errorDisplay(snapshot.error);
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(
      BuildContext context, Map<String, AccountLink> accountLinks) {
    var rows = <GestureDetector>[];

    accountLinks.forEach((img, accountLink) {
      var url = baseUri + img;
      rows.add(GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AccountPageWidget(
                      account: fetchAccount(accountLink.id))));
        },
        child: Container(
          child: Text(accountLink.name, style: _font),
          decoration: BoxDecoration(
              color: Colors.orangeAccent,
              image: DecorationImage(
                fit: BoxFit.contain,
                alignment: FractionalOffset.topCenter,
                image: NetworkImage(url),
              )),
        ),
      ));
    });

    return GridView.count(crossAxisCount: 2, children: rows);
  }
}
