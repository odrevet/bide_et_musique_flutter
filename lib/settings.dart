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
      _rememberIdents = prefs.getBool('rememberIdents') ?? false;
      _autoConnect = prefs.getBool('autoConnect') ?? false;
    });
  }

  void _onToggleRadioQuality(bool value) {
    setState(() {
      _radioHiQuality = value;
      _saveOption('radioHiQuality', value);
    });
  }

  void _onTogglerememberIdents(bool value) {
    setState(() {
      _rememberIdents = value;
      _saveOption('rememberIdents', value);
    });
  }

  void _onToggleautoConnect(bool value) {
    setState(() {
      _autoConnect = value;
      _saveOption('autoConnect', value);
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
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.8)),
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
                CheckboxListTile(
                    title: Text('Se souvenir des identifiants'),
                    value: _rememberIdents,
                    onChanged: _onTogglerememberIdents),
                CheckboxListTile(
                    title: Text(
                        'Connexion au compte au démarrage de l\'application'),
                    value: _autoConnect,
                    onChanged: _onToggleautoConnect),
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
