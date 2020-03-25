import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart';
import 'manageAccount.dart';
import 'session.dart';
import 'utils.dart';

class IdentificationResponse {
  bool isLoggedIn;
  String loginMessage;
}

Future<IdentificationResponse> sendIdentifiers(
    String login, String password) async {
  var identificationResponse = IdentificationResponse();

  if (login.isEmpty) {
    identificationResponse.isLoggedIn = false;
    identificationResponse.loginMessage =
        'Veuillez entrer votre nom d\'utilisateur';
    return identificationResponse;
  }

  if (password.isEmpty) {
    identificationResponse.isLoggedIn = false;
    identificationResponse.loginMessage = 'Veuillez entrer votre mot de passe';
    return identificationResponse;
  }

  final url = '$baseUri/ident.html';
  var response;
  try {
    response =
        await Session.post(url, body: {'LOGIN': login, 'PASSWORD': password});
  } catch (e) {
    identificationResponse.isLoggedIn = false;
    identificationResponse.loginMessage = e.toString();
    return identificationResponse;
  }

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var confirm = document.getElementById('gd-encartblc').children[1];

    identificationResponse.loginMessage = confirm.innerHtml;

    if (confirm.children[0].innerHtml == 'Vous avez été identifié !') {
      dom.Element divAccount = document.getElementById('compte2');
      Session.accountLink.id = getIdFromUrl(
          divAccount.children[1].children[1].attributes['href']);
      Session.accountLink.name = login;
      identificationResponse.isLoggedIn = true;
    } else {
      identificationResponse.isLoggedIn = false;

      if (confirm.innerHtml
          .contains('Vous n\'avez pas été reconnu dans la base')) {
        identificationResponse.loginMessage =
            'Vous n\'avez pas été reconnu dans la base';
      }
    }
  } else {
    identificationResponse.isLoggedIn = false;
    identificationResponse.loginMessage =
        'Erreur (code status ${response.statusCode})';
  }

  return identificationResponse;
}

class IdentificationWidget extends StatefulWidget {
  IdentificationWidget({Key key}) : super(key: key);

  @override
  _IdentificationWidgetState createState() => _IdentificationWidgetState();
}

class _IdentificationWidgetState extends State<IdentificationWidget> {
  _IdentificationWidgetState();

  Future<IdentificationResponse> _identificationResponse;

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
      return LoggedInPage();
    } else {
      return Center(
        child: FutureBuilder<IdentificationResponse>(
          future: _identificationResponse,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data.isLoggedIn == true)
                return LoggedInPage();
              else if (snapshot.data.isLoggedIn == false) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text("Connexion à votre compte"),
                  ),
                  body: _buildViewLoginForm(context, snapshot.data),
                );
              }
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

    this.setState(() {
      _identificationResponse = sendIdentifiers(username, password);
    });

    if (_remember == true) {
      _saveSettings();
    }
  }

  void _onRememberToggle(bool value) {
    setState(() {
      _remember = value;
      _saveRemember();
    });
  }

  Widget _buildViewLoginForm(BuildContext context,
      [IdentificationResponse identificationResponse]) {
    var form = Form(
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
          identificationResponse != null &&
                  identificationResponse.isLoggedIn == false
              ? Container(
                  margin: EdgeInsets.only(top: 20.0),
                  child: Text(
                      'Erreur d\'authentification:\n${identificationResponse.loginMessage}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)))
              : Text(''),
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
            margin: EdgeInsets.only(top: 2.0),
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
    );

    return Container(padding: EdgeInsets.all(30.0), child: form);
  }
}
