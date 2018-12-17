import 'dart:io';

import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:aufwachen_soundboard/sound.dart';

const GITHUB_URL_PREFIX =
    'https://raw.githubusercontent.com/jonasholtkamp/aufwachen-soundboard/master/assets/audio/';

final sounds = [
  Sound('Wir kümmern uns', 'wirkuemmernuns.m4a'),
  Sound('Zunichte gerammelt!', 'zunichtegerammelt.m4a'),
  Sound('Puffjes gegessen', 'puffjesgegessen.m4a'),
  Sound('Puffjes gefahren', 'puffjesgefahren.m4a'),
  Sound('Angela Krank-Karrenbauer', 'akk.m4a'),
  Sound('Das kann nicht sein so!', 'daskannnichtseinso.m4a'),
  Sound('Entschuldigung!', 'entschuldigung.m4a'),
  Sound('Der Verlierer ist die SPD', 'verliererspd.m4a'),
];

enum PlayerState { stopped, playing, paused }

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AudioPlayer _audioPlayer;

  Sound _activeSound;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration;
  Duration _position;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _initSoundState();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.stop();
  }

  _getLeadingIcon(Sound sound) {
    if (!sound.cached) {
      return Padding(
        padding: EdgeInsets.all(6.0),
        child: Icon(Icons.cloud_download),
      );
    }

    if (_activeSound != sound) {
      return Padding(
        padding: EdgeInsets.all(6.0),
        child: Icon(Icons.play_arrow),
      );
    }

    return FittedBox(
      child: Stack(alignment: Alignment.center, children: <Widget>[
        Container(
          // padding: EdgeInsets.all(6.0),
          child: IconButton(
            icon: _isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            onPressed: () => _play(sound),
          ),
        ),
        _isPlaying || _isPaused
            ? new CircularProgressIndicator(
                value: _position != null && _position.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0.0,
                valueColor: new AlwaysStoppedAnimation(Colors.cyan),
              )
            : Container()
      ]),
    );
  }

  Future<File> _getLocalFile(Sound sound) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${sound.filename}');
  }

  Future _downloadFile(Sound sound) async {
    final file = await _getLocalFile(sound);
    final bytes = await readBytes('$GITHUB_URL_PREFIX${sound.filename}');

    await file.writeAsBytes(bytes);
    if (await file.exists()) {
      setState(() {
        sound.cached = true;
      });
    }
  }

  _delete(Sound sound) async {
    final file = await _getLocalFile(sound);
    await file.delete();

    if (!await file.exists()) {
      setState(() {
        sound.cached = false;
      });
    }
  }

  _play(Sound sound) async {
    if (_activeSound == sound) {
      if (_isPlaying) {
        final result = await _audioPlayer.pause();
        if (result == 1) setState(() => _playerState = PlayerState.paused);
      } else {
        final result = await _audioPlayer.resume();
        if (result == 1) setState(() => _playerState = PlayerState.playing);
      }
    } else {
      _activeSound = sound;
      final result = await _audioPlayer.play((await _getLocalFile(sound)).path,
          isLocal: true);
      if (result == 1) setState(() => _playerState = PlayerState.playing);
    }
  }

  _initAudioPlayer() {
    _audioPlayer = new AudioPlayer();

    _audioPlayer.durationHandler = (d) => setState(() {
          _duration = d;
        });

    _audioPlayer.positionHandler = (p) => setState(() {
          _position = p;
        });

    _audioPlayer.completionHandler = () {
      setState(() {
        _activeSound = null;
        _playerState = PlayerState.stopped;
        _position = _duration;
      });
    };
  }

  Future<bool> _isSoundCached(Sound sound) async {
    final file = await _getLocalFile(sound);
    return await file.exists();
  }

  _initSoundState() {
    sounds.forEach((sound) async {
      final cached = await _isSoundCached(sound);
      setState(() {
        sound.cached = cached;
      });
    });
  }

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
            leading: _getLeadingIcon(sound),
            title: Text(sound.title),
            onTap: () {
              if (sound.cached) {
                _play(sound);
              } else {
                _downloadFile(sound);
              }
            },
            onLongPress: () => _delete(sound),
          );
        },
      ),
    );
  }
}
