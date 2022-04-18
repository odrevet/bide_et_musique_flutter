import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song.dart';
import 'cover.dart';
import 'cover_viewer.dart';
import 'song_app_bar.dart';
import 'song_page.dart';

void launchSongPage(SongLink songLink, BuildContext context) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SongPageWidget(
              songLink: songLink, song: fetchSong(songLink.id))));
}

/// Display given songs in a ListView
class SongListingWidget extends StatefulWidget {
  final List<SongLink>? _songLinks;
  final split;

  SongListingWidget(this._songLinks, {this.split = false, Key? key})
      : super(key: key);

  @override
  SongListingWidgetState createState() => SongListingWidgetState();
}

class SongListingWidgetState extends State<SongListingWidget> {
  SongListingWidgetState();

  @override
  Widget build(BuildContext context) {
    var rows = <Widget>[];
    var latestInfo = "";

    for (SongLink songLink in widget._songLinks!) {
      String subtitle = '';
      subtitle = songLink.artist ?? "";

      if (songLink.info != null) {
        if (songLink.info!.isEmpty) {
          songLink.info = "Programmation générale";
        }
        if (this.widget.split == true && latestInfo != songLink.info!) {
          latestInfo = songLink.info!;
          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Divider(
                    indent: 20.0,
                    endIndent: 10.0,
                    thickness: 1,
                  ),
                ),
                Text(
                  songLink.info!,
                  style: TextStyle(color: Colors.blueGrey),
                ),
                Expanded(
                  child: Divider(
                    indent: 10.0,
                    endIndent: 20.0,
                    thickness: 1,
                  ),
                ),
              ],
            ),
          );
        } else if (this.widget.split != true) {
          subtitle += ' • ' + songLink.info!;
        }
      }

      rows.add(ListTile(
        leading: GestureDetector(
          child: CoverThumb(songLink),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<Null>(
              builder: (BuildContext context) {
                return CoverViewer(songLink);
              },
              fullscreenDialog: true)),
        ),
        title: Text(
          songLink.name,
        ),
        trailing: songLink.isNew ? Icon(Icons.fiber_new) : null,
        subtitle: Text(subtitle),
        onTap: () => launchSongPage(songLink, context),
        onLongPress: () {
          fetchSong(songLink.id).then((song) {
            showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return SimpleDialog(
                  contentPadding: EdgeInsets.all(20.0),
                  children: [SongActionMenu(song)],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0))),
                );
              },
            );
          });
        },
      ));
    }

    return ListView(children: rows);
  }
}
