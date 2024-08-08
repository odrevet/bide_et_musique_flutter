import 'dart:async';

import 'package:bide_et_musique/utils.dart';
import 'package:flutter/material.dart';

import '../../models/song.dart';
import '../cover.dart';
import '../error_display.dart';

class AiringCard extends StatefulWidget {
  final Future<Song> _song;

  const AiringCard(this._song, {super.key});

  @override
  State<AiringCard> createState() => _AiringCardState();
}

class _AiringCardState extends State<AiringCard> {
  _AiringCardState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Song>(
        future: widget._song,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Hero(
              tag: createTag(snapshot.data!),
              child: CoverWithGesture(
                  songLink: snapshot.data,
                  displayPlaceholder: false,
                  fadeInDuration: const Duration()),
            );
          } else if (snapshot.hasError) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [ErrorDisplay(snapshot.error)]);
          }

          return Container();
        },
      ),
    );
  }
}
