import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../player.dart' show audioHandler;
import '../widgets/song_airing_notifier.dart';

class RadioStreamButton extends StatefulWidget {
  final Future<SongAiring>? _songAiring;

  const RadioStreamButton(this._songAiring, {Key? key}) : super(key: key);

  @override
  State<RadioStreamButton> createState() => _RadioStreamButtonState();
}

class _RadioStreamButtonState extends State<RadioStreamButton> {
  @override
  Widget build(BuildContext context) {
    Widget label = const Text("Écouter la radio",
        style: TextStyle(
          fontSize: 20.0,
        ));

    return FutureBuilder<SongAiring>(
      future: widget._songAiring,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          label = RichText(
            text: TextSpan(
              text: 'Écouter la radio ',
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                    text: '\n${snapshot.data!.nbListeners} auditeurs',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
              ],
            ),
          );
        }
        return ElevatedButton.icon(
          icon: const Icon(Icons.radio, size: 40),
          label: label,
          onPressed: () async {
            SongAiringNotifier().songAiring!.then((song) async {
              await audioHandler
                  .customAction('set_radio_mode', <String, dynamic>{'radio_mode': true});
              await audioHandler.customAction('set_song', song.toJson());
              await audioHandler.play();
            });
          },
        );
      },
    );
  }
}
