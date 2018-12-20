import 'package:aufwachen_soundboard/file_handler.dart';
import 'package:aufwachen_soundboard/preferences.dart';
import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:aufwachen_soundboard/sound.dart';

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
  Preferences _preferences = Preferences();

  Sound _activeSound;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration;
  Duration _position;

  bool _filteringStarred = false;
  bool _searching = false;
  TextEditingController _filter = TextEditingController();
  String _searchString;

  get soundsToDisplay => sounds
      .where((s) => !_filteringStarred || s.starred)
      .where((s) =>
          !_searching ||
          _searchString == null ||
          s.title.toLowerCase().contains(_searchString.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _initSounds();

    _filter.addListener(() {
      setState(() => _searchString = _filter.text);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.stop();
  }

  _isActive(Sound sound) => sound == _activeSound;

  bool _isPlaying(Sound sound) =>
      _playerState == PlayerState.playing && _isActive(sound);

  void downloadFinishedHandler(Sound sound) {
    setState(() {
      sound.cached = true;
    });
  }

  void deletionHandler(Sound sound) {
    setState(() {
      sound.cached = false;
      _handleStop();
    });
  }

  /*
   * UI item logic
   */
  _getTitle() => _searching
      ? new TextField(
          controller: _filter,
          decoration: new InputDecoration(
            prefixIcon: new Icon(Icons.search),
            hintText: 'Search...',
          ),
        )
      : Text(widget.title);

  _getSearchIcon() => _searching ? Icon(Icons.close) : Icon(Icons.search);

  ListTile _listBuilder(Sound sound) {
    return ListTile(
      leading: _getLeadingIcon(sound),
      title: Text(sound.title),
      onLongPress: () => sound.cached ? delete(sound, deletionHandler) : null,
      trailing: _getTrailingIcon(sound),
    );
  }

  _getLeadingIcon(Sound sound) {
    if (!sound.cached) {
      return IconButton(
        icon: Icon(Icons.cloud_download),
        onPressed: () => downloadFile(sound, downloadFinishedHandler),
      );
    }

    return FittedBox(
      child: Stack(alignment: Alignment.center, children: <Widget>[
        IconButton(
            icon:
                _isPlaying(sound) ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            onPressed: () => _play(sound)),
        _isActive(sound)
            ? new CircularProgressIndicator(
                value: _position != null && _position.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0.0,
                valueColor: new AlwaysStoppedAnimation(Colors.cyan),
              )
            : Container(),
      ]),
    );
  }

  _getTrailingIcon(Sound sound) {
    return IconButton(
      icon: sound.starred
          ? Icon(Icons.star, color: Theme.of(context).toggleableActiveColor)
          : Icon(Icons.star_border),
      onPressed: () {
        _preferences.save(sound.filename, "starred");
        setState(() {
          sound.starred = !sound.starred;
        });
      },
    );
  }

  _getFilterStarredIcon() => _filteringStarred
      ? Icon(Icons.star, color: Theme.of(context).toggleableActiveColor)
      : Icon(Icons.star_border);

  /*
   * Action handlers
   */
  _play(Sound sound) async {
    if (!_isActive(sound)) {
      _activeSound = sound;
      final file = await getLocalFile(sound);
      final result = await _audioPlayer.play(file.path, isLocal: true);
      if (result == 1) setState(() => _playerState = PlayerState.playing);
      return;
    }

    if (_isPlaying(sound)) {
      final result = await _audioPlayer.pause();
      if (result == 1) setState(() => _playerState = PlayerState.paused);
      return;
    }

    final result = await _audioPlayer.resume();
    if (result == 1) setState(() => _playerState = PlayerState.playing);
  }

  _filterStarred() async {
    setState(() => _filteringStarred = !_filteringStarred);
    _preferences.save("_filteringStarred", _filteringStarred.toString());
  }

  _toggleSearch() {
    setState(() => _searching = !_searching);
  }

  /*
   * Initialization
   */
  _initAudioPlayer() {
    _audioPlayer = new AudioPlayer();
    _audioPlayer.durationHandler = (d) => setState(() => _duration = d);
    _audioPlayer.positionHandler = (p) => setState(() => _position = p);
    _audioPlayer.completionHandler = () => setState(() => _handleStop());
  }

  _initSounds() async {
    sounds.forEach((sound) async {
      final file = await getLocalFile(sound);
      final cached = await file.exists();
      final starred = await _preferences.get(sound.filename) == "starred";
      setState(() {
        sound.cached = cached;
        sound.starred = starred;
      });
    });

    _filteringStarred = await _preferences.get("_filteringStarred") == "true";
  }

  _handleStop() {
    _activeSound = null;
    _playerState = PlayerState.stopped;
    _position = _duration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _getTitle(),
        actions: <Widget>[
          IconButton(
            icon: _getFilterStarredIcon(),
            onPressed: () => _filterStarred(),
          ),
          IconButton(icon: _getSearchIcon(), onPressed: () => _toggleSearch()),
        ],
      ),
      body: ListView.builder(
        itemCount: soundsToDisplay.length,
        itemBuilder: (buildContext, index) =>
            _listBuilder(soundsToDisplay[index]),
      ),
    );
  }
}
