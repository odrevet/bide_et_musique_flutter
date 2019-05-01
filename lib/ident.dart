import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';
import 'utils.dart';
import 'account.dart';
import 'manageFavoritesWidget.dart';
import 'manageAccountPageWidget.dart';

class Session {
  static final Session _singleton = Session._internal();

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

Future<Session> sendIdent(String login, String password) async {
  final url = '$baseUri/ident.html';
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
      return Center(child: _buildViewLoggedIn(context, _localSession));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text("Connexion à votre compte"),
        ),
        body: Center(
          child: FutureBuilder<Session>(
            future: _session,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
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
    var account = Account(session.id, "");

    //disconnect button
    var actions = <Widget>[];
    actions.add(IconButton(
      icon: Icon(Icons.close),
      onPressed: () {
        _localSession.id = null;
        _localSession.headers = {};
        Navigator.pop(context);
      },
    ));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          actions: actions,
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.account_circle)),
              Tab(icon: Icon(Icons.star)),
            ],
          ),
          title: Text('Gestion de votre compte'),
        ),
        body: TabBarView(
          //physics: NeverScrollableScrollPhysics(),
          children: [
            ManageAccountPageWidget(
                account: account,
                accountInformations: fetchAccountInformations(session.id)),
            ManageFavoritesWidget(session: session),
          ],
        ),
      ),
    );
  }

  Widget _buildViewLoginForm(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(30.0),
        child: Form(
          child: ListView(
            children: <Widget>[
              TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Nom utilisateur',
                  )),
              TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                  )),
              Container(
                child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                    child: Text(
                      'Se connecter',
                    ),
                    onPressed: _performLogin,
                    color: Colors.orangeAccent),
                margin: EdgeInsets.only(top: 20.0),
              ),
              Column(children: [
                Text("Pas de compte ? "),
                RaisedButton(
                  onPressed: _launchURL,
                  child: Text('En créer un sur bide-et-musique.com'),
                ),
              ])
            ],
          ),
        ));
  }

  _launchURL() async {
    const url = '$baseUri/create_account.html';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
