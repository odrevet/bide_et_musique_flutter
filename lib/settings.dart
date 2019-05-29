import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _radioHiQuality = true;
  bool _openSongPage = false;
  bool _rememberIdents = false;
  bool _autoConnect = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _radioHiQuality = prefs.getBool('radioHiQuality') ?? true;
    });
  }

  void _onToggleRadioQuality(bool value) {
    setState(() {
      _radioHiQuality = value;
      _saveOption('radioHiQuality', value);
    });
  }

  _saveOption(String name, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(name, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Options'),
      ),
      body: Center(
          child: Container(
        child: Stack(children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.7)),
            ),
          ),
          PageView(
            children: <Widget>[
              Form(
                  child: ListView(children: [
                CheckboxListTile(
                    title: Text('Radio haute qualitée'),
                    value: _radioHiQuality,
                    onChanged: _onToggleRadioQuality),
                /*CheckboxListTile(
                    title: Text(
                        'Ouvrir la page de la chanson en cours de lecture lors de l\'appuye dans la barre de notification'),
                    value: _openSongPage,
                    onChanged: ),
                CheckboxListTile(
                    title: Text('Se souvenir des identifiants'),
                    value: _rememberIdents,
                    onChanged: ),
                CheckboxListTile(
                    title: Text(
                        'Connexion au compte au démarrage de l\'application'),
                    value: _autoConnect,
                    onChanged: ),*/
              ])),
            ],
          )
        ]),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bm_logo.png'),
          ),
        ),
      )),
    );
  }
}
