import 'package:aufwachen_soundboard/sound.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audio_cache.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static AudioCache audioPlayer = new AudioCache(prefix: 'audio/');

  _play(String filename) => () async {
        await audioPlayer.play(filename);
      };

  final sounds = [
    Sound('Wir kümmern uns', 'wirkuemmernuns.m4a'),
    Sound('Zunichte gerammelt!', 'zunichtegerammelt.m4a'),
    Sound('Puffjes gegessen', 'puffjesgegessen.m4a')
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: sounds.length,
        itemBuilder: (buildContext, index) {
          var sound = sounds[index];
          return ListTile(
            title: Text(sound.title),
            onTap: _play(sound.filename),
          );
        },
      ),
    );
  }
}
