import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song.dart';
import 'error_display.dart';
import 'song_airing/song_airing_notifier.dart';
import 'song_airing/song_airing_title.dart';
import 'song_listing.dart';

class TitlesWidget extends StatefulWidget {
  final SongAiringNotifier _songAiringNotifier = SongAiringNotifier();

  TitlesWidget({super.key});

  @override
  State<TitlesWidget> createState() => _TitlesWidgetState();
}

class _TitlesWidgetState extends State<TitlesWidget> {
  Future<Map<String, List<SongLink>>>? _songLinks;
  late VoidCallback listener;

  void updateTitles() {
    setState(() {
      _songLinks = fetchTitles();
    });
  }

  @override
  initState() {
    // Update songs list and appbar when song airing changes
    listener = () {
      if (mounted) updateTitles();
    };

    _songLinks = fetchTitles();
    widget._songAiringNotifier.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    widget._songAiringNotifier.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Map<String, List<SongLink>>>(
        future: _songLinks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(snapshot.data!);
          } else if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Ouille ouille ouille !')),
              body: Center(
                child: ErrorDisplay(Exception(snapshot.error.toString())),
              ),
            );
          }

          // By default, show a loading spinner
          return Scaffold(
            appBar: AppBar(title: const Text('Chargement des titres')),
            body: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildView(Map<String, List<SongLink>> songLinks) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: SongAiringTitle(
                orientation,
                widget._songAiringNotifier.songAiring,
              ),
              bottom: orientation == Orientation.portrait
                  ? const TabBar(
                      tabs: [
                        Tab(text: 'A venir sur la platine'),
                        Tab(text: 'De retour dans leur bac'),
                      ],
                    )
                  : null,
            ),
            body: orientation == Orientation.portrait
                ? TabBarView(
                    children: [
                      SongListingWidget(songLinks['next'], split: true),
                      SongListingWidget(songLinks['past']),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      Expanded(
                        child: SongListingWidget(
                          songLinks['next'],
                          split: true,
                        ),
                      ),
                      Expanded(child: SongListingWidget(songLinks['past'])),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
