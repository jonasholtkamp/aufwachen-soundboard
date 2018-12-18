class Sound {
  final String title;
  final String filename;
  bool cached = false;
  bool starred = false;

  Sound(this.title, this.filename);

  @override
  String toString() => '{ title: "$title", filename: "$filename", cached: "$cached" }';
}
