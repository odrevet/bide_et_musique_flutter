import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/session.dart';
import '../models/song.dart';
import '../services/account.dart';
import '../services/random_song.dart';
import '../services/schedule.dart';
import '../services/song.dart';
import '../services/thematics.dart';
import '../utils.dart';
import 'account.dart';
import 'account/identification.dart';
import 'account/manage_account.dart';
import 'forums.dart';
import 'new_songs.dart';
import 'now_song.dart';
import 'pochettoscope_page.dart';
import 'schedule.dart';
import 'search.dart';
import 'settings.dart';
import 'song_page/song_page.dart';
import 'thematics.dart';
import 'titles.dart';
import 'trombidoscope.dart';
import 'wall.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  late String _accountTitle;
  late PackageInfo _packageInfo;

  @override
  void initState() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        _packageInfo = packageInfo;
      });
    });

    super.initState();
    _setAccountTitle();
  }

  void _setAccountTitle() {
    setState(() {
      _accountTitle = Session.accountLink.id == null
          ? 'Connexion'
          : '${Session.accountLink.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 120.0,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fitWidth,
                  image: AssetImage('assets/bandeau.png'),
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fitWidth,
                    image: AssetImage('assets/bm_logo_white.png'),
                  ),
                ),
                child: Container(),
              ),
            ),
          ),
          ListTile(
            title: Text(_accountTitle),
            leading: const Icon(Icons.account_circle),
            trailing: Session.accountLink.id == null
                ? null
                : const DisconnectButton(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Identification()),
              ).then((_) {
                _setAccountTitle();
              });
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Titres'),
            leading: const Icon(Icons.queue_music),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TitlesWidget()),
              );
            },
          ),
          ListTile(
            title: const Text('Programmation'),
            leading: const Icon(Icons.calendar_view_day),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Schedule(schedule: fetchSchedule()),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Thématiques'),
            leading: const Icon(Icons.photo_album),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ThematicPageWidget(programLinks: fetchThematics()),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Morceau du moment'),
            leading: const Icon(Icons.access_alarms),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NowSongsWidget(nowSongs: fetchNowSongs()),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Morceau au pif'),
            leading: const Icon(Icons.shuffle),
            onTap: () {
              fetchRandomSongId().then(
                (id) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SongPageWidget(
                      songLink: SongLink(id: id!, name: ''),
                      song: fetchSong(id),
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Recherche'),
            leading: const Icon(Icons.search),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Search()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Mur des messages'),
            leading: const Icon(Icons.comment),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WallWidget()),
              );
            },
          ),
          ListTile(
            title: const Text('Forums'),
            leading: const Icon(Icons.forum),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForumWidget()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Pochettoscope'),
            leading: const Icon(Icons.image),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PochettoScopePage(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Trombidoscope'),
            leading: const Icon(Icons.face),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrombidoscopeWidget(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Nouvelles entrées'),
            leading: const Icon(Icons.fiber_new),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongsWidget(songs: fetchNewSongs()),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Options'),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            title: const Text('À propos'),
            leading: const Icon(Icons.info),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: _packageInfo.appName,
              applicationVersion: _packageInfo.version,
              applicationIcon: Image.asset(
                'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
              ),
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Application Bide&Musique par \n',
                        style: defaultStyle,
                      ),
                      TextSpan(
                        text: 'Olivier Drevet',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AccountPage(account: fetchAccount(84482)),
                            ),
                          ),
                      ),
                      TextSpan(
                        text: '\n\nDistribuée sous la ',
                        style: defaultStyle,
                      ),
                      TextSpan(
                        text: 'license GPLv3',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchURL(
                            'https://www.gnu.org/licenses/gpl-3.0.fr.html',
                          ),
                      ),
                      TextSpan(
                        text: '\n\nCode source disponible sur ',
                        style: defaultStyle,
                      ),
                      TextSpan(
                        text: 'github.com\n\n',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchURL(
                            'https://github.com/odrevet/bide-et-musique-flutter',
                          ),
                      ),
                      TextSpan(
                        text: 'Manuel Utilisateur en ligne',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchURL(
                            'https://github.com/odrevet/bide-et-musique-flutter/wiki/Manuel-Utilisateur',
                          ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
