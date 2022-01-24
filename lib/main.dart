import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'player.dart';
import 'widgets/bide_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ByteData data =
      await PlatformAssetBundle().load('assets/lets-encrypt-r3.pem');
  SecurityContext.defaultContext
      .setTrustedCertificatesBytes(data.buffer.asUint8List());

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'fr.odrevet.bide_et_musique.channel.audio',
      androidNotificationChannelName: 'Audio playback for Bide et Musique',
      androidNotificationOngoing: true,
    ),
  );
  runApp(BideApp());
}
