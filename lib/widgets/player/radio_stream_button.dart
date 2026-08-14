import 'package:flutter/material.dart';

import '../../models/song.dart';
import '../../services/player.dart' show audioHandler;
import '../song_airing/song_airing_notifier.dart';

class RadioStreamButton extends StatefulWidget {
  final Future<SongAiring>? _songAiring;

  const RadioStreamButton(this._songAiring, {super.key});

  @override
  State<RadioStreamButton> createState() => _RadioStreamButtonState();
}

class _RadioStreamButtonState extends State<RadioStreamButton> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongAiring>(
      future: widget._songAiring,
      builder: (context, snapshot) {
        return Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade300.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () async {
                  SongAiringNotifier().songAiring!.then((song) async {
                    await audioHandler.customAction(
                      'set_radio_mode',
                      <String, dynamic>{'radio_mode': true},
                    );
                    await audioHandler.customAction('set_song', song.toJson());
                    await audioHandler.play();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radio,
                        size: 22,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Écouter la radio",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
