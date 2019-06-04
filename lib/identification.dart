import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart';
import 'manageAccount.dart';
import 'manageFavorites.dart';
import 'song.dart';
import 'utils.dart';

class Session {
  static var accountLink = AccountLink();

  static Map<String, String> headers = {};

  static Future<http.Response> get(String url) async {
    http.Response response = await http.get(url, headers: headers);
    updateCookie(response);
    return response;
  }

  static Future<http.Response> post(String url, dynamic data) async {
    http.Response response = await http.post(url, body: data, headers: headers);
    updateCookie(response);
    return response;
  }

  static void updateCookie(http.Response response) {
    String rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }
}

Future<bool> sendIdent(String login, String password) async {
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
      Session.updateCookie(response);

      dom.Element divAccount = document.getElementById('compte2');
      Session.accountLink.id = extractAccountId(
          divAccount.children[1].children[1].attributes['href']);
      Session.accountLink.name = login;
      return true;
    }
    else return false;
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
  Future<bool> _isLoggedIn;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    _loadRemember();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (Session.accountLink.id != null) {
      return _buildViewLoggedIn(context);
    } else {
      return Center(
        child: FutureBuilder<bool>(
          future: _isLoggedIn,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return _buildViewLoggedIn(context);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            // By default, show the login form
            return Scaffold(
              appBar: AppBar(
                title: Text("Connexion à votre compte"),
              ),
              body: _buildViewLoginForm(context),
            );
          },
        ),
      );
    }
  }

  //save or load login
  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _remember = prefs.getBool('rememberIdents') ?? false;
    if (_remember == true) {
      _usernameController.text = prefs.getString('login') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
    }
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('login', _usernameController.text);
    prefs.setString('password', _passwordController.text);
  }

  _loadRemember() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _remember = (prefs.getBool('rememberIdents') ?? false);
    });
  }

  _saveRemember() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool('rememberIdents', _remember);
    });
  }

  _clearSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = '';
      _passwordController.text = '';
      prefs.setString('login', _usernameController.text);
      prefs.setString('password', _passwordController.text);
    });
  }

  void _performLogin() {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      this.setState(() {
        sendIdent(username, password);
      });

      if (_remember == true) {
        _saveSettings();
      }
    }
  }

  Widget _buildViewLoggedIn(BuildContext context) {
    var account = AccountLink(id: Session.accountLink.id);

    //disconnect button
    var actions = <Widget>[];
    actions.add(IconButton(
      icon: Icon(Icons.close),
      onPressed: () {
        Session.accountLink.id = null;
        Session.headers = {};
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
              Tab(icon: Icon(Icons.exposure_plus_1)),
            ],
          ),
          title: Text('Gestion de votre compte'),
        ),
        body: TabBarView(
          children: [
            ManageAccountPageWidget(
                accountLink: account,
                account: fetchAccount(Session.accountLink.id)),
            ManageFavoritesWidget(),
            SongListingFutureWidget(fetchVotes())
          ],
        ),
      ),
    );
  }

  void _onRememberToggle(bool value) {
    setState(() {
      _remember = value;
      _saveRemember();
    });
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
              CheckboxListTile(
                  title: Text("Se souvenir des identifiants"),
                  value: _remember,
                  onChanged: _onRememberToggle),
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
              Divider(),
              Column(children: [
                Text("Pas de compte ? "),
                RaisedButton(
                  onPressed: () => launchURL('$baseUri/create_account.html'),
                  child: Text('En créer un sur bide-et-musique.com'),
                ),
              ]),
              Divider(),
              Column(children: [
                RaisedButton(
                  onPressed: _clearSettings,
                  child: Text('Oublier les identifiants'),
                ),
              ])
            ],
          ),
        ));
  }
}
