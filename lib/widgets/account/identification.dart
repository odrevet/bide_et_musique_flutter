import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/session.dart';
import '../../services/identification.dart';
import '../../utils.dart';
import 'manage_account.dart';

class Identification extends StatefulWidget {
  const Identification({super.key});

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
                  appBar: AppBar(title: const Text("Connexion à votre compte")),
                  body: _buildViewLoginForm(context, snapshot.data),
                );
              }
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            // By default, show the login form
            return Scaffold(
              appBar: AppBar(title: const Text("Connexion à votre compte")),
              body: _buildViewLoginForm(context),
            );
          },
        ),
      );
    }
  }

  //save or load login
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _remember = prefs.getBool('rememberIdents') ?? false;
    if (_remember == true) {
      _usernameController.text = prefs.getString('login') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('login', _usernameController.text);
    prefs.setString('password', _passwordController.text);
  }

  Future<void> _loadRemember() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _remember = (prefs.getBool('rememberIdents') ?? false);
    });
  }

  Future<void> _saveRemember() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool('rememberIdents', _remember!);
    });
  }

  Future<void> _clearSettings() async {
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

  Widget _buildViewLoginForm(
    BuildContext context, [
    IdentificationResponse? identificationResponse,
  ]) {
    final theme = Theme.of(context);
    var form = Form(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 24),
          Text(
            'Connectez-vous à votre compte',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Nom d\'utilisateur',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),
          if (identificationResponse != null &&
              identificationResponse.isLoggedIn == false) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${identificationResponse.loginMessage}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text("Se souvenir des identifiants"),
            value: _remember,
            onChanged: _onRememberToggle,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Se connecter'),
            onPressed: _performLogin,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  "Pas de compte ?",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Créer un compte sur le site'),
                  onPressed: () => launchURL('$baseUri/create_account.html'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text('Oublier les identifiants enregistrés'),
              onPressed: _clearSettings,
            ),
          ),
        ],
      ),
    );

    return form;
  }
}
