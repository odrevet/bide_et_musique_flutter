import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song.dart';
import 'cover_viewer.dart';
import 'song_app_bar.dart';
import 'song_page.dart';
import 'cover.dart';

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

  SongListingWidget(this._songLinks, {Key? key}) : super(key: key);

  @override
  SongListingWidgetState createState() => SongListingWidgetState();
}

class SongListingWidgetState extends State<SongListingWidget> {
  SongListingWidgetState();

  @override
  Widget build(BuildContext context) {
    var rows = <ListTile>[];

    for (SongLink songLink in widget._songLinks!) {
      String subtitle = songLink.artist == null ? '' : songLink.artist!;

      if (songLink.info != null && songLink.info!.isNotEmpty) {
        if (subtitle != '') subtitle += ' • ';
        subtitle += songLink.info!;
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

