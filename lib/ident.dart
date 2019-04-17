import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'utils.dart';
import 'account.dart';

class Session {
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
  final url = '$host/ident.html';
  final response = await http.post(url, body: {'LOGIN': login, 'PASSWORD': password});

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var  confirm = document.getElementById('gd-encartblc').children[1].children[0].innerHtml;
    if (confirm == 'Vous avez été identifié !') {
      var session = Session();
      session.updateCookie(response);

      dom.Element divAccount = document.getElementById('compte2');
      session.id = extractAccountId(divAccount.children[1].children[1].attributes['href']);
      return session;
    }
    else{
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

  Future<Session> session;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Votre compte"),
      ),
      body: Center(
        child: FutureBuilder<Session>(
          future: session,
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

  void _performLogin() {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if(username.isNotEmpty && password.isNotEmpty) {
      this.setState(() {
        session = sendIdent(username, password);
      });
    }
  }

  Widget _buildViewLoggedIn(BuildContext context, Session session) {
    return  ManageAccountWidget(session: session);
  }

  Widget _buildViewLoginForm(BuildContext context) {
    return Center(child:
    ListView  (
      shrinkWrap: true,
      padding: EdgeInsets.only(left: 24.0, right: 24.0),
      children: <Widget>[
        TextFormField(controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Nom utilisateur',
              contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
            )),
        TextFormField(controller: _passwordController, obscureText: true,
            decoration: InputDecoration(
              hintText: 'Mot de passe',
              contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
            )),
        RaisedButton(
          onPressed: _performLogin,
          child: Text('OK'),
          padding: EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        )
      ],
    ));
  }
}
