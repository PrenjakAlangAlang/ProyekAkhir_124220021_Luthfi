import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:quran/database/hive_config.dart';
import 'package:quran/database/user_model.dart';

class SurahDetailPage extends StatefulWidget {
  final String surahNumber;
  final String surahName;
  final String translation;
  final String playAudio;
  final String revelationPlace;
  final int ayatCount;

  const SurahDetailPage({
    Key? key,
    required this.surahNumber,
    required this.surahName,
    required this.translation,
    required this.playAudio,
    required this.revelationPlace,
    required this.ayatCount,
  }) : super(key: key);

  @override
  _SurahDetailPageState createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  List<dynamic> ayatList = [];
  bool isLoading = true;
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String? currentAudioUrl;
  UserModel? user;

  @override
  void initState() {
    super.initState();
    fetchAyatData();
    setupAudioPlayer();
    loadUser();
  }

  Future<void> loadUser() async {
    final activeUserBox = Hive.box(HiveConfig.activeUserBoxName);
    final userData = activeUserBox.get('activeUser');

    if (userData != null) {
      final userBox = Hive.box<UserModel>(HiveConfig.userBoxName);
      user = userBox.values.firstWhere((u) => u.email == userData['email']);
      setState(() {});
    }
  }

  void setupAudioPlayer() {
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
  }

  Future<void> playPauseAudio() async {
    try {
      if (isPlaying) {
        await audioPlayer.stop();
        setState(() {
          isPlaying = false;
        });
      } else {
        await audioPlayer.play(UrlSource(widget.playAudio));
        setState(() {
          isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: ${e.toString()}')),
      );
    }
  }

  Future<void> fetchAyatData() async {
    try {
      final response = await http.get(
        Uri.parse('https://equran.id/api/surat/${widget.surahNumber}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          ayatList = data['ayat'];
          isLoading = false;
          currentAudioUrl = data['audio'];
        });
      } else {
        throw Exception('Gagal mengambil data ayat');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> toggleBookmark(String ayatReference) async {
    if (user != null) {
      setState(() {
        if (user!.bookmarks.contains(ayatReference)) {
          user!.bookmarks.remove(ayatReference);
        } else {
          user!.bookmarks.add(ayatReference);
        }
      });
      await user!.save();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Align(
          alignment: Alignment(0, 0.5),
          child: const Text(
            'Surah',
            style: TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.surahName} - ${widget.translation}',
                            style: TextStyle(
                                color: const Color(0xFF1DB954),
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.revelationPlace} - ${widget.ayatCount} ayat',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: playPauseAudio,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: ayatList.length,
                    itemBuilder: (context, index) {
                      final ayat = ayatList[index];
                      final ayatReference =
                          '${widget.surahNumber}:${index + 1}';

                      return Card(
                        color: const Color(0xFF191414),
                        margin: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 16,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ayat['ar'],
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      user != null &&
                                              user!.bookmarks
                                                  .contains(ayatReference)
                                          ? Icons.bookmark
                                          : Icons.bookmark_outline,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        toggleBookmark(ayatReference),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ayat['tr'],
                                      style: const TextStyle(
                                        color: Color(0xFF1DB954),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ayat['idn'],
                                      style: const TextStyle(
                                        color: Color(0xFF6AFF9F),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
