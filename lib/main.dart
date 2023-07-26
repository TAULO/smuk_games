import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fs/html.dart' if (dart.library.io) 'package:fs/io.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.camera});

  final CameraDescription camera;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Så er der bong',
        camera: camera,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.camera});

  final CameraDescription camera;

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final audioPlayer = AudioPlayer();
  final finishAudioPlayer = AudioPlayer();
  final drikAudioPlayer = AudioPlayer();
  Duration duration = const Duration();
  Duration? currPosition = const Duration();
  double sliderValue = 0;
  double currDuration = 0;
  double currSongPosition = 0;
  int random = 0;
  bool hasRandom = false;
  bool toggleClick = false;
  bool useDrikDrik = false;
  bool stopFlash = false;
  bool isLocked = false;

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    Future handleAsync() async {
      String path = "audio/bong.mp4";
      await audioPlayer.setSourceAsset(path);

      Duration? sourceDuraton = await audioPlayer.getDuration();
      duration = Duration(seconds: sourceDuraton!.inSeconds);

      // dirty reload
      setState(() {
        sliderValue = duration.inSeconds.toDouble() / duration.inSeconds / 2;
        currDuration = duration.inSeconds.toDouble() / 2;
      });

      handleAsync();

      // play random song
      audioPlayer.onPositionChanged.listen((pos) {
        if (random > 0 && pos.inSeconds == random) {
          audioPlayer.stop();
          _playFinishSong();
        }
      });

      // lock specifitc UI elements when playing
      audioPlayer.onPlayerStateChanged.listen((state) {
        if (state.name == "playing") {
          setState(() {
            isLocked = true;
          });
        }
      });

      // play drik song if checked
      finishAudioPlayer.onPlayerStateChanged.listen((state) {
        if (useDrikDrik && state.name == "completed") {
          _playDrikDrik();
        } else if (!useDrikDrik && state.name == "completed") {
          _stopSong();
        }
      });
    }

    // turn flashes off
    drikAudioPlayer.onPlayerStateChanged.listen((state) {
      if (state.name == "completed") {
        _stopSong();
      }
    });

    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
  }

  int _getRandomNum() {
    Random random = Random();
    return random.nextInt(currDuration.toInt()) + 1;
  }

  void _playSong() {
    setState(() {
      toggleClick = !toggleClick;
    });

    if (!toggleClick) {
      audioPlayer.pause();
      return;
    }

    if (!hasRandom) {
      random = _getRandomNum();
      hasRandom = true;
    }

    Source? source = audioPlayer.source;
    if (source != null) {
      audioPlayer.play(source);
    }
  }

  _stopSong() {
    setState(() {
      toggleClick = false;
      currSongPosition = 0;
      isLocked = false;
    });
    audioPlayer.stop();
    finishAudioPlayer.stop();
    drikAudioPlayer.stop();
    hasRandom = false;
    stopFlash = true;
  }

  void _updateSlider(double curr) {
    sliderValue = (duration.inSeconds * curr) / duration.inSeconds;
    currDuration = (duration.inSeconds * curr);

    setState(() {
      sliderValue = curr;
    });
  }

  List<String> _getSongsPath() {
    try {
      Directory dir = Directory(
          "/Users/taulo/Desktop/Flutter practice/smuk_games/assets/audio");

      String correctPath(path) => "audio/$path";
      return dir
          .listSync()
          .where((e) => e.path.toLowerCase().endsWith(".mp3"))
          .map(
              (e) => correctPath(e.path.substring(e.path.lastIndexOf("/") + 1)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  int lastRandomIndex = -1;
  void _playFinishSong() async {
    String pathIndex(index) => "audio/song$index.mp3";
    List<String> songs = _getSongsPath();

    songs = [];

    if (songs.isEmpty) {
      // update this value if more songs are being added to the audio folder
      for (int i = 1; i <= 22; i++) {
        songs.add(pathIndex(i));
      }
    }

    Random random = Random();
    int rndIndex = random.nextInt(songs.length - 1) + 1;

    int stop = 1;
    while (stop > 10 || lastRandomIndex == rndIndex) {
      rndIndex = random.nextInt(songs.length - 1) + 1;
      stop++;
    }

    await finishAudioPlayer.setSourceAsset(songs[rndIndex]);

    Source? source = finishAudioPlayer.source;
    if (source != null) {
      finishAudioPlayer.play(source, volume: 1);
    }

    lastRandomIndex = rndIndex;
  }

  void _playDrikDrik() async {
    await drikAudioPlayer.setSourceAsset("audio/derbong.mp4");

    Source? source = drikAudioPlayer.source;

    if (source != null) {
      drikAudioPlayer.play(source);

      await _initializeControllerFuture;

      stopFlash = false;

      while (!stopFlash) {
        _controller.setFlashMode(FlashMode.torch);
        await Future.delayed(const Duration(milliseconds: 100));
        _controller.setFlashMode(FlashMode.off);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    onPressed: () => _playSong(),
                    child: Icon(!toggleClick ? Icons.play_arrow : Icons.pause),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      stopFlash = true;
                      _stopSong();
                    },
                    child: const Icon(Icons.stop),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: CheckboxMenuButton(
                value: useDrikDrik,
                onChanged: !isLocked
                    ? (state) => setState(() {
                          useDrikDrik = state!;
                        })
                    : null,
                child: const Text(
                    "Drik, drik, drik, drik, drik, drik, driiiiiiiiiiik!"),
              ),
            ),
            // postion slider
            StreamBuilder(
                stream: audioPlayer.onPositionChanged,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        Slider(
                          value: (snapshot.data!.inSeconds.toDouble() / 100),
                          onChanged: null,
                        ),
                      ],
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Tryk på start!"),
                    );
                  }
                }),
            // stop slider
            Slider(
                value: sliderValue,
                onChanged: !isLocked ? (curr) => _updateSlider(curr) : null),
            Text("${currDuration.toStringAsFixed(0)} sekunder"),
          ],
        ),
      ),
    );
  }
}
