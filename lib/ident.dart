import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'utils.dart';
import 'account.dart';

class Session {
  static final Session _singleton = new Session._internal();

  factory Session() {
    return _singleton;
  }

  Session._internal();

  String id;

  Map<String, String> headers = {};

  Future<http.Response> get(String url) async {
    http.Response response = await http.get(url, headers: headers);
    updateCookie(response);
    return response;
  }

  Future<http.Response> post(String url, dynamic data) async {
    http.Response response = await http.post(url, body: data, headers: headers);
    updateCookie(response);
    return response;
  }

  void updateCookie(http.Response response) {
    String rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }
}

var gSession = Session();

Future<Session> sendIdent(String login, String password) async {
  final url = '$host/ident.html';
  final response =
      await http.post(url, body: {'LOGIN': login, 'PASSWORD': password});

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var confirm = document
        .getElementById('gd-encartblc')
        .children[1]
        .children[0]
        .innerHtml;
    if (confirm == 'Vous avez été identifié !') {
      var session = Session();
      session.updateCookie(response);

      dom.Element divAccount = document.getElementById('compte2');
      session.id = extractAccountId(
          divAccount.children[1].children[1].attributes['href']);
      return session;
    } else {
      return null;
    }
  } else {
    throw Exception('Failed to load login reponse');
  }
}

class IdentWidget extends StatefulWidget {
  IdentWidget({Key key}) : super(key: key);

  @override
  _IdentWidgetState createState() => _IdentWidgetState();
}

class _IdentWidgetState extends State<IdentWidget> {
  _IdentWidgetState();

  Future<Session> _session;
  Session _localSession;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localSession = Session();
  }

  @override
  Widget build(BuildContext context) {
    if (_localSession.id != null) {
      var actions = <Widget>[];
      actions.add(IconButton(
        icon: new Icon(Icons.close),
        onPressed: () {
          _localSession.id = null;
          _localSession.headers = {};
          Navigator.pop(context);
        },
      ));
      return Scaffold(
          appBar: AppBar(
            title: Text("Votre compte"),
            actions: actions,
          ),
          body: Center(child: _buildViewLoggedIn(context, _localSession)));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text("Votre compte"),
        ),
        body: Center(
          child: FutureBuilder<Session>(
            future: _session,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                gSession = snapshot.data;
                return _buildViewLoggedIn(context, snapshot.data);
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }

              // By default, show the login form
              return _buildViewLoginForm(context);
            },
          ),
        ),
      );
    }
  }

  void _performLogin() {
    String username = _usernameController.text;
    String password = _passwordController.text;
    if (username.isNotEmpty && password.isNotEmpty) {
      this.setState(() {
        _session = sendIdent(username, password);
      });
    }
  }

  Widget _buildViewLoggedIn(BuildContext context, Session session) {
    return ManageAccountWidget(session: session);
  }

  Widget _buildViewLoginForm(BuildContext context) {
    return Container(
        padding: new EdgeInsets.all(30.0),
        child: new Form(
          child: new ListView(
            children: <Widget>[
              new TextFormField(
                  controller: _usernameController,
                  decoration: new InputDecoration(
                    hintText: 'Nom utilisateur',
                  )),
              new TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: new InputDecoration(
                    hintText: 'Mot de passe',
                  )),
              new Container(
                child: new RaisedButton(
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(30.0)),
                    child: new Text(
                      'Se connecter',
                    ),
                    onPressed: _performLogin,
                    color: Colors.orangeAccent),
                margin: new EdgeInsets.only(top: 20.0),
              )
            ],
          ),
        ));
  }
}
