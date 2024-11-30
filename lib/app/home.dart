import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:quran/app/ayat.dart';

import 'package:quran/app/profile.dart';

import 'package:quran/app/terakhirdibaca.dart';

import 'package:quran/database/hive_config.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String displayName = 'Luthfi Nurafiq';
  String photoURL = 'images/default_profile.png';
  List<dynamic> surahs = [];
  bool isLoading = true;
  String errorMessage = '';
  int _currentIndex = 0;

  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String currentlyPlayingId = '';

  @override
  void initState() {
    super.initState();
    fetchSurahs();
    _loadUserData();

    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        currentlyPlayingId = '';
      });
    });
  }

  Future<void> _loadUserData() async {
    final userData = await HiveConfig.getActiveUser();
    if (userData != null) {
      setState(() {
        displayName = userData['username'];
        photoURL = userData['photoPath'] ?? 'images/default_profile.png';
      });
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playAudio(String audioUrl, String surahId) async {
    try {
      if (isPlaying && currentlyPlayingId == surahId) {
        await audioPlayer.stop();
        setState(() {
          isPlaying = false;
          currentlyPlayingId = '';
        });
      } else {
        if (isPlaying) {
          await audioPlayer.stop();
        }
        await audioPlayer.play(UrlSource(audioUrl));
        setState(() {
          isPlaying = true;
          currentlyPlayingId = surahId;
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memutar audio')),
      );
    }
  }

  Future<void> fetchSurahs() async {
    try {
      final response = await http.get(Uri.parse('https://equran.id/api/surat'));
      if (response.statusCode == 200) {
        setState(() {
          surahs = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat surah');
      }
    } catch (e) {
      print('Error saat mengambil surah: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal mengambil data. Silakan coba lagi.';
      });
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home, no action needed
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TerakhirDibaca()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: photoURL.startsWith('images/')
                  ? AssetImage(photoURL)
                  : FileImage(File(photoURL)) as ImageProvider,
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hi, $displayName',
                style: const TextStyle(color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Make the most of it!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF176D35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Ayo Kawan Baca\nAl-Quran!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Image.asset(
                      'images/ustad.png',
                      height: 120,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Silahkan Baca Al-Quran',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                color: const Color(0xFF191414),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Surah',
                        style: TextStyle(
                            color: Color(0xFF1DB954),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : errorMessage.isNotEmpty
                              ? Center(
                                  child: Text(errorMessage,
                                      style:
                                          const TextStyle(color: Colors.red)))
                              : Expanded(
                                  child: ListView.builder(
                                    itemCount: surahs.length,
                                    itemBuilder: (context, index) {
                                      final surah = surahs[index];
                                      final surahId = surah['nomor'].toString();
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        color: const Color(0xFF121212),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SurahDetailPage(
                                                  surahNumber: (surah['nomor'])
                                                      .toString(),
                                                  surahName:
                                                      surah['nama_latin'],
                                                  translation: surah['arti'],
                                                  playAudio: surah['audio'],
                                                  revelationPlace:
                                                      surah['tempat_turun'],
                                                  ayatCount:
                                                      surah['jumlah_ayat'],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 30,
                                                  child: Text(
                                                    surahId,
                                                    style: const TextStyle(
                                                      color: Color(0xFF1DB954),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        surah['nama_latin'],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        '${surah['arti']} - ${surah['jumlah_ayat']} ayat',
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF1DB954),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    currentlyPlayingId ==
                                                            surahId
                                                        ? Icons.stop
                                                        : Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                  onPressed: () {
                                                    playAudio(surah['audio'],
                                                        surahId);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Color(0xFF1DB954),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_add), label: 'Terakhir Dibaca'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: _onNavItemTapped,
      ),
    );
  }
}
