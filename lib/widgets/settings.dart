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
  int _relay = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
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

  void _onToggleRelay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _relay == 1 ? _relay = 2 : _relay = 1;
    });
    prefs.setInt('relay', _relay);
  }

  Future<void> _saveOptionBool(String name, bool? value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(name, value!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Options')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Diffusion',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              title: const Text('Relais'),
              subtitle: const Text('Serveur de diffusion utilisé'),
              trailing: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                ],
                selected: {_relay},
                onSelectionChanged: (value) => _onToggleRelay(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Compte',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Se souvenir des identifiants'),
                  subtitle: const Text('Garder le login et mot de passe'),
                  value: _rememberIdents,
                  onChanged: _onToggleRememberIdents,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                CheckboxListTile(
                  title: const Text('Connexion automatique'),
                  subtitle: const Text(
                    'Connexion au compte au démarrage',
                  ),
                  value: _autoConnect,
                  onChanged: _rememberIdents == true
                      ? _onToggleAutoConnect
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Appareil',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: CheckboxListTile(
              title: const Text('Empêcher la mise en veille'),
              subtitle: const Text(
                'Garder l\'écran allumé pendant la lecture',
              ),
              value: _wakelock,
              onChanged: _onToggleWakeLock,
            ),
          ),
        ],
      ),
    );
  }
}
