import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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
        song.title = stripTags(songEntry['name']);
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

class ProgramPageWidget extends StatelessWidget {
  final Future<Program> program;

  ProgramPageWidget({Key key, this.program}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Program>(
        future: program,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          var loadingMessage = 'Chargement';

          return Scaffold(
            appBar: AppBar(
              title: Text(loadingMessage),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, Program program) {
    var listing;
    if (program.type == 'program-liste') {
      listing = SongListingWidget(program.songs);
    } else {
      listing = Text('Pas de liste disponible');
    }

    var nestedScrollView = NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            backgroundColor: Theme.of(context).canvasColor,
            expandedHeight: 200.0,
            automaticallyImplyLeading: false,
            floating: true,
            flexibleSpace:
                FlexibleSpaceBar(background: Html(data: program.description)),
          ),
        ];
      },
      body: Center(
          child: Container(
        child: Stack(children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.7)),
            ),
          ),
          listing
        ]),
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(stripTags(program.name)),
      ),
      body: nestedScrollView,
    );
  }
}
