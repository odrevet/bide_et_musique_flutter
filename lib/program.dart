import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'utils.dart';
import 'song.dart';
import 'dart:convert';

class Program {
  String id;
  String name;
  String description;
  List<String> airedOn;
  List<String> inMeta;
  List<Song> songs;

  Program({this.id, this.name, this.description, this.airedOn, this.songs});

  factory Program.fromJson(Map<String, dynamic> json) {
    var songs = <Song>[];
    for (var songEntry in json['songs']) {
      var song = Song();
      song.id = songEntry['song_id'].toString();
      song.title = songEntry['name'];
      song.artist = songEntry['alias'];
      songs.add(song);
    }

    return Program(
        id: json['id'].toString(),
        name: json['name'],
        description: json['description'],
        songs: songs);
  }
}

Future<Program> fetchProgram(String programId) async {
  var artist;
  final url = '$baseUri/program/$programId';

  final responseJson = await http.get(url);

  if (responseJson.statusCode == 200) {
    try {
      artist =
          Program.fromJson(json.decode(utf8.decode(responseJson.bodyBytes)));
    } catch (e) {
      print('Error while decoding Program informations : ' + e.toString());
    }
  } else {
    throw Exception('Failed to load Program informations');
  }

  return artist;
}

String extractProgramId(str) {
  final idRegex = RegExp(r'/program/(\d+).html');
  var match = idRegex.firstMatch(str);
  if (match != null) {
    return match[1];
  } else {
    return null;
  }
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
          SongListingWidget(program.songs)
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
