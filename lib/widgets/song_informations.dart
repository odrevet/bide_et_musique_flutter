import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/artist.dart';
import '../utils.dart';
import 'artist.dart';
import 'search.dart';

class SongInformations extends StatelessWidget {
  final Song song;
  final bool compact;

  const SongInformations({required this.song, this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    var linkStyle = const TextStyle(
      fontSize: 16.0,
      color: Colors.red,
      fontWeight: FontWeight.bold,
    );

    var textSpans = <TextSpan>[];

    if (!compact && song.year != 0) {
      textSpans.add(TextSpan(text: 'Année\n', style: defaultStyle));

      textSpans.add(
        TextSpan(
          text: '${song.year}\n\n',
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text(
                      'Recherche de l\'année "${song.year.toString()}"',
                    ),
                  ),
                  body: SearchResults(song.year.toString(), '7'),
                ),
              ),
            ),
        ),
      );
    }

    if (!compact && song.artist != null) {
      textSpans.add(TextSpan(text: 'Artiste\n', style: defaultStyle));

      textSpans.add(
        TextSpan(
          text: '${song.artist!}\n\n',
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ArtistPageWidget(artist: fetchArtist(song.artistId)),
              ),
            ),
        ),
      );
    }

    if (song.durationPretty != null) {
      textSpans.add(TextSpan(text: 'Durée \n', style: defaultStyle));

      textSpans.add(
        TextSpan(text: '${song.durationPretty!}\n\n', style: defaultStyle),
      );
    }

    if (song.label != null && song.label != '') {
      textSpans.add(TextSpan(text: 'Label\n', style: defaultStyle));

      textSpans.add(
        TextSpan(
          text: '${song.label!}\n\n',
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Recherche du label "${song.label}"'),
                  ),
                  body: SearchResults(song.label, '5'),
                ),
              ),
            ),
        ),
      );
    }

    if (song.reference != null && song.reference != '') {
      textSpans.add(TextSpan(text: 'Référence\n', style: defaultStyle));

      textSpans.add(
        TextSpan(text: '${song.reference}\n\n', style: defaultStyle),
      );
    }

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(style: defaultStyle, children: textSpans),
      ),
    );
  }
}
