import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song.dart';
import 'error_display.dart';
import 'song_airing_notifier.dart';
import 'song_listing.dart';

class TitlesWidget extends StatefulWidget {
  final SongAiringNotifier _songAiringNotifier = SongAiringNotifier();

  TitlesWidget({Key? key}) : super(key: key);

  @override
  _TitlesWidgetState createState() => _TitlesWidgetState();
}

class _TitlesWidgetState extends State<TitlesWidget> {
  Future<Map<String, List<SongLink>>>? _songLinks;
  late VoidCallback listener;
  String _title = "Les titres";

  void updateTitles() {
    setState(() {
      _songLinks = fetchTitles();
    });
  }

  @override
  initState() {
    // Update song list and title when song airing changes
    listener = () {
      if (mounted) updateTitles();
      widget._songAiringNotifier.songAiring!.then((song) async {
        setState(() {
          _title = song.name;
        });
      });
    };

    _songLinks = fetchTitles();
    widget._songAiringNotifier.addListener(listener);

    // Update title on page load
    fetchAiring().then((song) => setState(() {
          _title = song.name;
        }));
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
                appBar: AppBar(title: Text('Ouille ouille ouille !')),
                body: Center(
                    child: ErrorDisplay(Exception(snapshot.error.toString()))));
          }

          // By default, show a loading spinner
          return Scaffold(
            appBar: AppBar(title: Text('Chargement des titres')),
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildView(Map<String, List<SongLink>> songLinks) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          bottom: TabBar(
            tabs: [
              Tab(text: 'A venir sur la platine'),
              Tab(text: 'De retour dans leur bac'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SongListingWidget(songLinks['next'], split: true),
            SongListingWidget(songLinks['past']),
          ],
        ),
      ),
    );
  }
}
