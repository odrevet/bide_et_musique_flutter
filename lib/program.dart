import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'pochettoscopeWidget.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

class Program {
  int id;
  String type;
  String name;
  String description;
  List<String> airedOn;
  List<String> inMeta;
  List<SongLink> songs;

  Program({this.id, this.name, this.description, this.airedOn, this.type});

  Program.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type = json['type'],
        name = stripTags(json['name']),
        description = json['description'] {
    if (this.type == 'program-liste') {
      var songs = <SongLink>[];
      for (var songEntry in json['songs']) {
        var song = SongLink();
        song.id = songEntry['song_id'];
        song.name = stripTags(songEntry['name']);
        song.artist = stripTags(songEntry['alias']);
        songs.add(song);
      }
      this.songs = songs;
    }
  }
}

Future<Program> fetchProgram(int programId) async {
  var program;
  final url = '$baseUri/program/$programId';

  final responseJson = await Session.get(url);

  if (responseJson.statusCode == 200) {
    try {
      program =
          Program.fromJson(json.decode(utf8.decode(responseJson.bodyBytes)));
    } catch (e) {
      program = Program();
      program.id = '?';
      program.type = '?';
      program.name = '?';
      program.description = e.toString();
    }
  } else {
    throw Exception('Failed to load Program with id $programId');
  }

  return program;
}

class ProgramPageWidget extends StatefulWidget {
  final Future<Program> program;

  ProgramPageWidget({Key key, this.program}) : super(key: key);

  @override
  _ProgramPageWidgetState createState() => _ProgramPageWidgetState();
}

class _ProgramPageWidgetState extends State<ProgramPageWidget> {
  bool _viewPochettoscope = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Program>(
        future: widget.program,
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return _buildView(context, snapshot.data);
          else if (snapshot.hasError)
            return Text("${snapshot.error}");

          return Scaffold(
            appBar: AppBar(
              title: Text('Chargement')
            ),
            body: Center(
              child: CircularProgressIndicator()
            )
          );
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, Program program) {
    var listing;
    if (program.type == 'program-liste') {
      if (_viewPochettoscope == true)
        listing = PochettoscopeWidget(songLinks: program.songs);
      else
        listing = SongListingWidget(program.songs);
    } else
      listing = Text('Pas de liste disponible');

    return Scaffold(
      appBar: AppBar(
        title: Text(stripTags(program.name)),
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: _switchViewButton()
          )
        ],
      ),
      body: Center(
          child: listing),
    );
  }

  Widget _switchViewButton(){
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewPochettoscope = !_viewPochettoscope;
        });
      },
      child: Icon(
        _viewPochettoscope == true ? Icons.image : Icons.queue_music,
      ),
    );
  }
}
