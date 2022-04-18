import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/artist.dart';
import '../utils.dart';
import 'song_listing.dart';

class ArtistPageWidget extends StatelessWidget {
  final Future<Artist?>? artist;

  const ArtistPageWidget({Key? key, this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Artist?>(
        future: artist,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          var loadingMessage = 'Chargement';

          return Scaffold(
            appBar: AppBar(
              title: Text(loadingMessage),
            ),
            body: const Center(
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
                              onTap: () => launchURL(artist.site!),
                              child: Text(artist.site!, style: linkStyle),
                            ),
                          Text(artist.alias!),
                          if (artist.dates != null) Text(artist.dates!)
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
