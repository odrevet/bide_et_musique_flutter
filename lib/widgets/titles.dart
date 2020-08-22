import 'dart:async';

import 'package:flutter/material.dart';

import 'song.dart';
import 'song_airing_notifier.dart';
import '../utils.dart';
import '../models/song.dart';
import '../services/song.dart';

class TitlesWidget extends StatefulWidget {
  final SongAiringNotifier _songAiring = SongAiringNotifier();

  TitlesWidget({Key key}) : super(key: key);

  @override
  _TitlesWidgetState createState() => _TitlesWidgetState();
}

class _TitlesWidgetState extends State<TitlesWidget> {
  Future<Map<String, List<SongLink>>> _songLinks;
  VoidCallback listener;

  void updateTitles() {
    setState(() {
      _songLinks = fetchTitles();
    });
  }

  @override
  initState() {
    listener = () {
      if (mounted) updateTitles();
    };

    _songLinks = fetchTitles();
    widget._songAiring.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    widget._songAiring.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Map<String, List<SongLink>>>(
        future: _songLinks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(snapshot.data);
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
          title: Text('Les titres'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'A venir sur la platine'),
              Tab(text: 'De retour dans leur bac'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SongListingWidget(songLinks['next']),
            SongListingWidget(songLinks['past']),
          ],
        ),
      ),
    );
  }
}
