import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'model/board_adapter.dart';

import 'game_view.dart';

//done
//package name
//icon launcher
//policy
//rate, more app
//splash screen

void main() async {
  //Allow only portrait mode on Android & iOS
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  //Make sure Hive is initialized first and only after register the adapter.
  await Hive.initFlutter();
  Hive.registerAdapter(BoardAdapter());

  runApp(const ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: true,
      debugShowMaterialGrid: false,
      title: '2048',
      home: GameView(),
    ),
  ));
}
