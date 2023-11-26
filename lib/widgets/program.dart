import 'dart:async';

import 'package:flutter/material.dart';

import '../models/program.dart';
import 'html_with_style.dart';
import 'pochettoscope.dart';
import 'song_listing.dart';

class ProgramPage extends StatefulWidget {
  final Future<Program>? program;

  const ProgramPage({super.key, this.program});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  bool _viewPochettoscope = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Program>(
        future: widget.program,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          return Scaffold(
              appBar: AppBar(title: const Text('Chargement')),
              body: const Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, Program program) {
    Widget listing;
    if (program.type == 'program-liste') {
      if (_viewPochettoscope == true) {
        listing = PochettoscopeWidget(songLinks: program.songs!);
      } else {
        listing = SongListingWidget(program.songs);
      }
    } else {
      listing = const Text('Pas de liste disponible');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name!),
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: program.description != null && program.airedOn!.isNotEmpty
                  ? displayInfoButton(program)
                  : null),
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: _switchViewButton())
        ],
      ),
      body: Center(child: listing),
    );
  }

  Widget displayInfoButton(Program program) {
    String airedOn = '';
    for (var airedOnEntry in program.airedOn!) {
      airedOn += '\n$airedOnEntry';
    }

    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return SimpleDialog(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0)),
              title: Text(program.name!),
              children: [
                HtmlWithStyle(data: program.description),
                if (program.airedOn!.isNotEmpty)
                  Text('Dernière diffusion $airedOn')
              ],
            );
          },
        );
      },
      child: const Icon(Icons.info_outline),
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
