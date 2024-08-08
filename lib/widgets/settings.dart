import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _rememberIdents = false;
  bool? _autoConnect = false;
  bool? _wakelock = false;
  bool? _dynamicTheming = true;
  int _relay = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberIdents = prefs.getBool('rememberIdents') ?? false;
      _autoConnect = prefs.getBool('autoConnect') ?? false;
      _wakelock = prefs.getBool('wakelock') ?? false;
      _relay = prefs.getInt('relay') ?? 1;
    });
  }

  void _onToggleRememberIdents(bool? value) {
    setState(() {
      _rememberIdents = value;
      _saveOptionBool('rememberIdents', value);
    });
  }

  void _onToggleAutoConnect(bool? value) {
    setState(() {
      _autoConnect = value;
      _saveOptionBool('autoConnect', value);
    });
  }

  void _onToggleWakeLock(bool? value) {
    setState(() {
      _wakelock = value;
      WakelockPlus.toggle(enable: _wakelock!);
      _saveOptionBool('wakelock', value);
    });
  }

  void _onToggleDynamicTheming(bool? value) {
    setState(() {
      _dynamicTheming = value;
      WakelockPlus.toggle(enable: _dynamicTheming!);
      _saveOptionBool('dynamictheming', value);
    });
  }

  void _onToggleRelay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _relay == 1 ? _relay = 2 : _relay = 1;
    });
    prefs.setInt('relay', _relay);
  }

  _saveOptionBool(String name, bool? value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(name, value!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Options'),
      ),
      body: Center(
          child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bm_logo.png'),
          ),
        ),
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
                ListTile(
                  title: const Text('Relais'),
                  trailing: SizedBox(
                      width: 42,
                      child: TextButton(
                          onPressed: _onToggleRelay,
                          child: Text(_relay.toString()))),
                ),
                const Divider(),
                CheckboxListTile(
                    title: const Text('Se souvenir des identifiants'),
                    value: _rememberIdents,
                    onChanged: _onToggleRememberIdents),
                CheckboxListTile(
                    title: const Text(
                        'Connexion au compte au démarrage de l\'application'),
                    value: _autoConnect,
                    onChanged:
                        _rememberIdents == true ? _onToggleAutoConnect : null),
                CheckboxListTile(
                    title: const Text('Empêcher la mise en veille'),
                    value: _wakelock,
                    onChanged: _onToggleWakeLock),
                CheckboxListTile(
                    title: const Text('Theme dynamique'),
                    value: _dynamicTheming,
                    onChanged: _onToggleDynamicTheming),
              ])),
            ],
          )
        ]),
      )),
    );
  }
}
