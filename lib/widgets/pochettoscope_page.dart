// @dart=2.9

import 'package:flutter/material.dart';

import '../services/pochettoscope.dart';
import 'pochettoscope.dart';

class PochettoScopePage extends StatelessWidget {
  final Widget child;

  PochettoScopePage({this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Le pochettoscope'),
        ),
        body: PochettoscopeWidget(onEndReached: fetchPochettoscope));
  }
}
