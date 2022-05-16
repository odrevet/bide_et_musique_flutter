import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/song.dart';
import '../services/favorite.dart';
import '../services/song.dart';
import '../session.dart';
import '../utils.dart';
import 'song_player.dart';

class SongAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Future<Song>? _song;

  const SongAppBar(this._song, {Key? key})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  @override
  _SongAppBarState createState() => _SongAppBarState();
}

class _SongAppBarState extends State<SongAppBar> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Song>(
      future: widget._song,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Song? song = snapshot.data;
          Widget songActionButton = IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        contentPadding: const EdgeInsets.all(20.0),
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0))),
                        children: [SongActionMenu(song)],
                      );
                    },
                  ));

          return AppBar(
            title: Text(snapshot.data!.name),
            actions: <Widget>[songActionButton],
          );
        } else if (snapshot.hasError) {
          return AppBar(title: const Text("Chargement"));
        }

        // By default, show a loading spinner
        return AppBar(title: const CircularProgressIndicator());
      },
    );
  }
}

/////////////////////////////////////////////////////////////////////////////
// Actions Buttons

class SongActionMenu extends StatelessWidget {
  final Song? _song;

  const SongActionMenu(this._song, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //add buttons to the actions menu
    //some action buttons are added when user is logged in
    //some action buttons are not available on some songs
    final actions = <Widget>[];
    //if the song can be listen, add the song player
    if (_song!.canListen) {
      actions.add(SongPlayerWidget(_song));
    }

    //if the user is logged in
    if (Session.accountLink.id != null) {
      if (_song!.canFavourite) {
        actions.add(SongFavoriteIconWidget(_song));
      }

      actions.add(SongVoteIconWidget(_song));
    }

    actions.add(SongOpenInBrowserIconWidget(_song));

    // Share buttons (message and song id)
    var actionsShare = <Widget>[];

    var shareSongStream = ElevatedButton.icon(
        icon: const Icon(Icons.music_note),
        label: const Text('Flux musical'),
        onPressed: () => Share.share(_song!.streamLink));

    actionsShare.add(SongShareIconWidget(_song));
    actionsShare.add(shareSongStream);

    //build widget for overflow button
    var popupMenuShare = <PopupMenuEntry<Widget>>[];
    for (Widget actionWidget in actionsShare) {
      popupMenuShare.add(PopupMenuItem<Widget>(child: actionWidget));
    }

    Widget popupMenuButtonShare = PopupMenuButton<Widget>(
        icon: const Icon(
          Icons.share,
        ),
        itemBuilder: (BuildContext context) => popupMenuShare);

    ///////////////////////////////////
    //// Copy
    var popupMenuCopy = <PopupMenuEntry<Widget>>[];
    popupMenuCopy
        .add(PopupMenuItem<Widget>(child: SongCopyLinkIconWidget(_song)));
    popupMenuCopy
        .add(PopupMenuItem<Widget>(child: SongCopyLinkHtmlIconWidget(_song)));

    Widget popupMenuButtonCopy = PopupMenuButton<Widget>(
        icon: const Icon(
          Icons.content_copy,
        ),
        itemBuilder: (BuildContext context) => popupMenuCopy);

    actions.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[popupMenuButtonCopy, popupMenuButtonShare],
    ));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions);
  }
}

////////////////////////////////
//// Add to favorite
class SongFavoriteIconWidget extends StatefulWidget {
  final Song? _song;

  const SongFavoriteIconWidget(this._song, {Key? key}) : super(key: key);

  @override
  _SongFavoriteIconWidgetState createState() => _SongFavoriteIconWidgetState();
}

class _SongFavoriteIconWidgetState extends State<SongFavoriteIconWidget> {
  _SongFavoriteIconWidgetState();

  @override
  Widget build(BuildContext context) {
    if (widget._song!.isFavourite) {
      return ElevatedButton.icon(
          icon: const Icon(Icons.star),
          label: const Text('Retirer des favoris'),
          onPressed: () async {
            int statusCode = await removeSongFromFavorites(widget._song!.id);
            if (statusCode == 200) {
              setState(() {
                widget._song!.isFavourite = false;
              });
            }
          });
    } else {
      return ElevatedButton.icon(
        icon: const Icon(Icons.star_border),
        label: const Text('Ajouter aux favoris'),
        onPressed: () async {
          int statusCode = await addSongToFavorites(widget._song!.link);
          if (statusCode == 200) {
            setState(() => widget._song!.isFavourite = true);
          } else {
            debugPrint(
                'Add song to favorites returned status code $statusCode');
          }
        },
      );
    }
  }
}

// Vote
class SongVoteIconWidget extends StatefulWidget {
  final Song? _song;

  const SongVoteIconWidget(this._song, {Key? key}) : super(key: key);

  @override
  _SongVoteIconWidgetState createState() => _SongVoteIconWidgetState();
}

class _SongVoteIconWidgetState extends State<SongVoteIconWidget> {
  _SongVoteIconWidgetState();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        icon: const Icon(Icons.exposure_plus_1),
        label: const Text('Voter'),
        onPressed: (widget._song!.hasVote ? null : callbackVote));
  }

  void callbackVote() async {
    int statusCode = await voteForSong(widget._song!.link);

    if (statusCode == 200) {
      setState(() {
        widget._song!.hasVote = true;
      });
    } else {
      debugPrint('Vote for song returned status code $statusCode');
    }
  }
}

////////////////////////////////
//// Share

class SongShareIconWidget extends StatelessWidget {
  final Song? _song;

  const SongShareIconWidget(this._song, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //share song button
    return ElevatedButton.icon(
        icon: const Icon(Icons.message),
        label: const Text('Message'),
        onPressed: () => Share.share(
            '''En ce moment j'écoute '${_song!.name}' sur Bide et Musique !

Tu peux consulter la fiche de cette chanson à l'adresse :
${_song!.link}

--------
Message envoyé avec l'application 'Bide et Musique'. Disponible pour  
* Android https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique 
* IOS https://apps.apple.com/fr/app/bide-et-musique/id1524513644''',
            subject: "'${_song!.name}' sur Bide et Musique"));
  }
}

////////////////////////////////
//// Copy

class SongCopyLinkIconWidget extends StatelessWidget {
  final Song? _song;

  const SongCopyLinkIconWidget(this._song, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //share song button
    return ElevatedButton.icon(
        icon: const Icon(Icons.link),
        label: const Text('Copier l\'url'),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: _song!.link));
        });
  }
}

class SongCopyLinkHtmlIconWidget extends StatelessWidget {
  final Song? _song;

  const SongCopyLinkHtmlIconWidget(this._song, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //share song button
    return ElevatedButton.icon(
        icon: const Icon(Icons.code),
        label: const Text('Copier le code HTML du lien'),
        onPressed: () => Clipboard.setData(ClipboardData(
            text: '<a href="${_song!.link}">${_song!.name}</a>')));
  }
}

////////////////////////////////
//// Open in browser

class SongOpenInBrowserIconWidget extends StatelessWidget {
  final Song? _song;

  const SongOpenInBrowserIconWidget(this._song, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //share song button
    return ElevatedButton.icon(
        icon: const Icon(Icons.open_in_browser),
        label: const Text('Ouvrir l\'url'),
        onPressed: () => launchURL(_song!.link));
  }
}
