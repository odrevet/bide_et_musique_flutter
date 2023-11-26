import 'package:bide_et_musique/models/song.dart';
import 'package:flutter/material.dart';

import '../services/pochettoscope.dart';
import 'pochettoscope.dart';

class PochettoScopePage extends StatelessWidget {
  final Widget? child;

  const PochettoScopePage({this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Le pochettoscope'),
        ),
        body: FutureBuilder<List<SongLink>>(
          future: fetchPochettoscope(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return PochettoscopeWidget(
                  songLinks: snapshot.data!, onEndReached: fetchPochettoscope);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            return const CircularProgressIndicator();
          },
        ));
  }
}
