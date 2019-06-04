import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart';
import 'manageAccount.dart';
import 'manageFavorites.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

Future<bool> sendIdent(String login, String password) async {
  final url = '$baseUri/ident.html';
  final response =
      await Session.post(url, body: {'LOGIN': login, 'PASSWORD': password});

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var confirm = document
        .getElementById('gd-encartblc')
        .children[1]
        .children[0]
        .innerHtml;
    if (confirm == 'Vous avez été identifié !') {
      dom.Element divAccount = document.getElementById('compte2');
      Session.accountLink.id = extractAccountId(
          divAccount.children[1].children[1].attributes['href']);
      Session.accountLink.name = login;
      return true;
    } else
      return false;
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
        _isLoggedIn = sendIdent(username, password);
      });

      if (_remember == true) {
        _saveSettings();
      }
    }
  }

  Widget _buildViewLoggedIn(BuildContext context) {
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
