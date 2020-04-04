import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'session.dart';
import 'song.dart';
import 'utils.dart';

Future<Artist> fetchArtist(int artistId) async {
  var artist;
  final url = '$baseUri/artist/$artistId';

  final responseJson = await Session.get(url);

  if (responseJson.statusCode == 200) {
    try {
      artist =
          Artist.fromJson(json.decode(utf8.decode(responseJson.bodyBytes)));
    } catch (e) {
      print('Error while decoding artist : ' + e.toString());
    }
  } else {
    throw Exception('Failed to load artist with id $artistId');
  }

  return artist;
}

class Artist {
  int id;
  String alias;
  String firstName;
  String lastName;
  String site;
  String birth;
  List<SongLink> disco;

  Artist({this.id, this.alias, this.site, this.birth, this.disco});

  Artist.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        alias = json['alias'],
        site = json['site'],
        birth = json['dates']['pretty'] {
    this.disco = <SongLink>[];
    for (var discoEntry in json['disco']) {
      this.disco.add(
          SongLink(id: discoEntry['id'], name: stripTags(discoEntry['name'])));
    }
  }

  String get urlImage {
    return '$baseUri/images/photos/ART${this.id}.jpg';
  }
}

class ArtistPageWidget extends StatelessWidget {
  final Future<Artist> artist;

  ArtistPageWidget({Key key, this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Artist>(
        future: artist,
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

  Widget _buildView(BuildContext context, Artist artist) {
    String urlArtistImage = artist.urlImage;

    var nestedScrollView = NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            backgroundColor: Theme.of(context).canvasColor,
            expandedHeight: 200.0,
            automaticallyImplyLeading: false,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
                background: Row(children: [
              Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                          child: InkWell(child: Image.network(urlArtistImage))),
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (artist.site != null)
                            GestureDetector(
                              onTap: () => launchURL(artist.site),
                              child: Text(artist.site),
                            ),
                          Text(artist.alias),
                          if (artist.birth != null) Text(artist.birth)
                        ],
                      )),
                    ],
                  ))
            ])),
          ),
        ];
      },
      body: Center(
          child: Container(
        child: Stack(children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9.6, sigmaY: 9.6),
            child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.7)),
            ),
          ),
          SongListingWidget(artist.disco)
        ]),
        decoration: BoxDecoration(
            image: DecorationImage(
          fit: BoxFit.fill,
          alignment: FractionalOffset.topCenter,
          image: NetworkImage(urlArtistImage),
        )),
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(stripTags(artist.alias)),
      ),
      body: nestedScrollView,
    );
  }
}
