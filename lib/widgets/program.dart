import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'pochettoscope.dart';
import 'song.dart';
import '../utils.dart';

import '../models/program.dart';

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
          else if (snapshot.hasError) return Text("${snapshot.error}");

          return Scaffold(
              appBar: AppBar(title: Text('Chargement')),
              body: Center(child: CircularProgressIndicator()));
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
              child: program.description != null && program.airedOn.isNotEmpty
                  ? displayInfoButton(program)
                  : null),
          Padding(
              padding: EdgeInsets.only(right: 20.0), child: _switchViewButton())
        ],
      ),
      body: Center(child: listing),
    );
  }

  Widget displayInfoButton(Program program) {
    String airedOn = '';
    for (var airedOnEntry in program.airedOn) {
      airedOn += '\n$airedOnEntry';
    }

    return GestureDetector(
      onTap: () {
        return showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return SimpleDialog(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0)),
              title: Text(program.name),
              children: [
                Html(data: program.description, linkStyle: linkStyle),
                if (program.airedOn.isNotEmpty)
                  Text('Dernière diffusion $airedOn')
              ],
            );
          },
        );
      },
      child: Icon(Icons.info_outline),
    );
  }

  Widget _switchViewButton() {
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
