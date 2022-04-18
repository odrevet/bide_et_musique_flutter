import 'package:flutter/material.dart';

import '../services/pochettoscope.dart';
import 'pochettoscope.dart';

class PochettoScopePage extends StatelessWidget {
  final Widget? child;

  const PochettoScopePage({this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Le pochettoscope'),
        ),
        body: const PochettoscopeWidget(onEndReached: fetchPochettoscope));
  }
}
