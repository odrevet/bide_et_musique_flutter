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
    var txtpresentation =
        document.getElementsByClassName('txtpresentation')[0].innerHtml;
    return stripTags(txtpresentation);
  } else {
    throw Exception('Failed to load account ');
  }
}

class AccountPageWidget extends StatelessWidget {
  Account account;
  Future<String> txtpresentation;

  AccountPageWidget({Key key, this.account, this.txtpresentation})
      : super(key: key);

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
    var url = 'http://www.bide-et-musique.com/images/photos/ACT' +
        account.id +
        '.jpg';

    return new Container(
      child: Center(
          child: Column(
        children: <Widget>[
          Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: Container(
                    decoration: new BoxDecoration(
                        image: new DecorationImage(
                      fit: BoxFit.fill,
                      alignment: FractionalOffset.topCenter,
                      image: new NetworkImage(url),
                    )),
                  )),
                  Expanded(
                    child: Text('TODO'), //SongPlayerWidget(song.id),
                  ),
                ],
              )),
          Expanded(
            flex: 7,
            child: Container(
              child: Stack(children: [
                new BackdropFilter(
                  filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: new Container(
                    decoration: new BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.7)),
                  ),
                ),
                SingleChildScrollView(child: Text(txtpresentation)),
              ]),
              decoration: new BoxDecoration(
                  image: new DecorationImage(
                fit: BoxFit.fill,
                alignment: FractionalOffset.topCenter,
                image: new NetworkImage(url),
              )),
            ),
          ),
        ],
      )),
    );
  }

  //  return new Container(child: Text(txtpresentation));

}
