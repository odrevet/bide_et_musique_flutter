import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart';

import '../models/session.dart';
import '../utils.dart';

class IdentificationResponse {
  bool? isLoggedIn;
  String? loginMessage;
}

Future<IdentificationResponse> sendIdentifiers(
  String login,
  String password,
) async {
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

  const url = '$baseUri/ident.html';
  Response response;
  try {
    response = await Session.post(
      url,
      body: {'LOGIN': login, 'PASSWORD': password},
    );
  } catch (e) {
    identificationResponse.isLoggedIn = false;
    identificationResponse.loginMessage = e.toString();
    return identificationResponse;
  }

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var confirm = document.getElementById('gd-encartblc')!.children[1];

    identificationResponse.loginMessage = confirm.innerHtml;

    if (confirm.children[0].innerHtml == 'Vous avez été identifié !') {
      dom.Element divAccount = document.getElementById('compte2')!;
      Session.accountLink.id = getIdFromUrl(
        divAccount.children[1].children[1].attributes['href']!,
      );
      Session.accountLink.name = login;
      identificationResponse.isLoggedIn = true;
    } else {
      identificationResponse.isLoggedIn = false;

      if (confirm.innerHtml.contains(
        'Vous n\'avez pas été reconnu dans la base',
      )) {
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
