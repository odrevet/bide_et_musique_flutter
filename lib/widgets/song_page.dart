import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:page_indicator/page_indicator.dart';

import '../models/song.dart';
import '../services/account.dart';
import '../services/song.dart';
import '../session.dart';
import '../utils.dart';
import 'account.dart';
import 'cover_viewer.dart';
import 'html_with_style.dart';
import 'song_app_bar.dart';
import 'song_information.dart';

class SongPageWidget extends StatefulWidget {
  final SongLink? songLink;
  final Future<Song>? song;

  SongPageWidget({Key? key, this.songLink, this.song}) : super(key: key);

  @override
  _SongPageWidgetState createState() => _SongPageWidgetState(this.song);
}

class _SongPageWidgetState extends State<SongPageWidget> {
  int? _currentPage;
  final _commentController = TextEditingController();
  Future<Song>? song;

  _SongPageWidgetState(this.song);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Song>(
      future: this.song,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildView(context, snapshot.data!);
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Ouille ouille ouille !')),
            body: Center(child: ErrorDisplay(snapshot.error)),
          );
        }

        return Center(child: _pageLoading(context, widget.songLink!));
      },
    );
  }

  void _openCoverViewerDialog(SongLink? songLink, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return CoverViewer(songLink);
        },
        fullscreenDialog: true));
  }

  Widget _pageLoading(BuildContext context, SongLink songLink) {
    var coverLink = songLink.coverLink;

    var loadingMessage = '';
    if (songLink.name.isNotEmpty) {
      loadingMessage += songLink.name;
    } else {
      loadingMessage = 'Chargement';
    }

    Widget body = Stack(children: <Widget>[
      CachedNetworkImage(
        imageUrl: coverLink,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: BoxFit.fitWidth),
          ),
        ),
        errorWidget: (context, url, error) =>
            Image.asset('assets/vinyl-default.jpg'),
      ),
      Align(alignment: Alignment.center, child: CircularProgressIndicator())
    ]);

    return Scaffold(appBar: AppBar(title: Text(loadingMessage)), body: body);
  }

  _newMessageDialog(BuildContext context, Song song) {
    _commentController.text = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          actions: [
            ElevatedButton.icon(
              icon: Icon(Icons.send),
              label: Text("Envoyer"),
              onPressed: () async {
                sendAddComment(song, _commentController.text);
                Navigator.of(context).pop();
                setState(() {
                  this.song = fetchSong(song.id);
                });
              },
            )
          ],
          title: Text('Nouveau commentaire'),
          content: TextFormField(
              maxLines: 5,
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Entrez votre commentaire ici',
              )),
        );
      },
    );
  }

  _editMessageDialog(BuildContext context, Song song, Comment comment) {
    _commentController.text = comment.body!;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          actions: [
            ElevatedButton.icon(
              icon: Icon(Icons.send),
              label: Text("Envoyer"),
              onPressed: () async {
                sendEditComment(song, comment, _commentController.text);
                setState(() {
                  this.song = fetchSong(song.id);
                });
                Navigator.of(context).pop();
              },
            )
          ],
          title: Text('Edition d\'un commentaire'),
          content: TextFormField(
              maxLines: 5,
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Entrez votre commentaire ici',
              )),
        );
      },
    );
  }

  Widget _buildView(BuildContext context, Song song) {
    final String coverLink = song.coverLink;
    final tag = createTag(widget.songLink!);

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
                          flex: 1,
                          child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Hero(
                                  tag: tag,
                                  child: InkWell(
                                      onTap: () {
                                        _openCoverViewerDialog(
                                            widget.songLink, context);
                                      },
                                      child: CachedNetworkImage(
                                          imageUrl: coverLink)))),
                        ),
                        Expanded(
                            flex: 1,
                            child: SingleChildScrollView(
                                child: SongInformations(song: song))),
                      ],
                    ))
              ])),
            ),
          ];
        },
        body: Stack(children: [
          CachedNetworkImage(
            imageUrl: song.coverLink,
            imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 9.6, sigmaY: 9.6),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.7)),
                  ),
                )),
          ),
          PageIndicatorContainer(
            align: IndicatorAlign.bottom,
            length: 2,
            indicatorSpace: 20.0,
            padding: const EdgeInsets.all(10),
            shape: IndicatorShape.circle(size: 8),
            indicatorColor: Theme.of(context).canvasColor,
            indicatorSelectorColor: Theme.of(context).colorScheme.secondary,
            child: PageView(
              onPageChanged: (int page) => setState(() {
                _currentPage = page;
              }),
              children: <Widget>[
                SingleChildScrollView(
                    child: Padding(
                  padding: EdgeInsets.only(left: 4.0, top: 2.0),
                  child: HtmlWithStyle(
                      data: song.lyrics == ''
                          ? '<center><i>Paroles non renseignées</i></center>'
                          : song.lyrics),
                )),
                _buildViewComments(context, song),
              ],
            ),
          )
        ]));

    Widget? postNewComment = Session.accountLink.id == null || _currentPage != 1
        ? null
        : FloatingActionButton(
            onPressed: () => _newMessageDialog(context, song),
            child: Icon(Icons.add_comment),
          );

    return Scaffold(
      appBar: SongAppBar(widget.song),
      body: nestedScrollView,
      floatingActionButton: postNewComment,
    );
  }

  Widget _buildViewComments(BuildContext context, Song song) {
    List<Comment> comments = song.comments;
    var rows = <Widget>[];
    String? loginName = Session.accountLink.name;
    var selfComment = TextStyle(
      color: Colors.red,
    );

    for (Comment comment in comments) {
      rows.add(ListTile(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AccountPage(account: fetchAccount(comment.author.id))));
          },
          title: HtmlWithStyle(data: comment.body),
          subtitle: Text('Par ' + comment.author.name! + ' ' + comment.time,
              style: comment.author.name == loginName ? selfComment : null),
          trailing: comment.author.name == loginName
              ? IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    _editMessageDialog(context, song, comment);
                  },
                )
              : null));
      rows.add(Divider());
    }

    return ListView(children: rows);
  }
}
