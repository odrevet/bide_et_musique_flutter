import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/identification.dart';
import '../session.dart';
import '../utils.dart';
import 'manage_account.dart';

class Identification extends StatefulWidget {
  const Identification({Key? key}) : super(key: key);

  @override
  State<Identification> createState() => _IdentificationState();
}

class _IdentificationState extends State<Identification> {
  _IdentificationState();

  Future<IdentificationResponse>? _identificationResponse;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool? _remember = false;

  @override
  void initState() {
    super.initState();
    _loadRemember();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (Session.accountLink.id != null) {
      return const LoggedInPage();
    } else {
      return Center(
        child: FutureBuilder<IdentificationResponse>(
          future: _identificationResponse,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isLoggedIn == true) {
                return const LoggedInPage();
              } else if (snapshot.data!.isLoggedIn == false) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text("Connexion à votre compte"),
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
                title: const Text("Connexion à votre compte"),
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
      prefs.setBool('rememberIdents', _remember!);
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

    setState(() {
      _identificationResponse = sendIdentifiers(username, password);
    });

    if (_remember == true) {
      _saveSettings();
    }
  }

  void _onRememberToggle(bool? value) {
    setState(() {
      _remember = value;
      _saveRemember();
    });
  }

  Widget _buildViewLoginForm(BuildContext context,
      [IdentificationResponse? identificationResponse]) {
    var form = Form(
      child: ListView(
        children: <Widget>[
          TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'Nom utilisateur',
              )),
          TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Mot de passe',
              )),
          identificationResponse != null &&
                  identificationResponse.isLoggedIn == false
              ? Container(
                  margin: const EdgeInsets.only(top: 20.0),
                  child: Text(
                      'Erreur d\'authentification:\n${identificationResponse.loginMessage}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)))
              : const Text(''),
          CheckboxListTile(
              title: const Text("Se souvenir des identifiants"),
              value: _remember,
              onChanged: _onRememberToggle),
          Container(
            margin: const EdgeInsets.only(top: 2.0),
            child: ElevatedButton(
                onPressed: _performLogin,
                child: const Text(
                  'Se connecter',
                )),
          ),
          const Divider(),
          Column(children: [
            const Text("Pas de compte ? "),
            ElevatedButton(
              onPressed: () => launchURL('$baseUri/create_account.html'),
              child: const Text('En créer un sur bide-et-musique.com'),
            ),
          ]),
          const Divider(),
          Column(children: [
            ElevatedButton(
              onPressed: _clearSettings,
              child: const Text('Oublier les identifiants'),
            ),
          ])
        ],
      ),
    );

    return Container(padding: const EdgeInsets.all(30.0), child: form);
  }
}
