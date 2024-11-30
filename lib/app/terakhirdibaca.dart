import 'package:flutter/material.dart';
import 'package:quran/app/home.dart';
import 'package:quran/app/profile.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quran/database/hive_config.dart';
import 'package:quran/database/user_model.dart';

class TerakhirDibaca extends StatefulWidget {
  const TerakhirDibaca({super.key});

  @override
  State<TerakhirDibaca> createState() => _TerakhirDibacaState();
}

class _TerakhirDibacaState extends State<TerakhirDibaca> {
  List<Map<String, dynamic>> bookmarkedAyatDetails = [];
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    final activeUserBox = Hive.box(HiveConfig.activeUserBoxName);
    final userData = activeUserBox.get('activeUser');

    if (userData != null) {
      final userBox = Hive.box<UserModel>(HiveConfig.userBoxName);
      final user =
          userBox.values.firstWhere((u) => u.email == userData['email']);
      List<String> bookmarkedAyat = user.bookmarks;

      for (String reference in bookmarkedAyat) {
        final parts = reference.split(':');
        if (parts.length == 2) {
          final surahNumber = parts[0];
          final ayatNumber = parts[1];
          await fetchAyatDetails(surahNumber, ayatNumber);
        }
      }
    }
  }

  Future<void> fetchAyatDetails(String surahNumber, String ayatNumber) async {
    try {
      final response = await http.get(
        Uri.parse('https://equran.id/api/surat/$surahNumber'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ayat = data['ayat'][int.parse(ayatNumber) - 1];

        setState(() {
          bookmarkedAyatDetails.add({
            'surahName': data['nama_latin'],
            'number': ayatNumber,
            'ar': ayat['ar'],
            'tr': ayat['tr'],
            'idn': ayat['idn'],
            'reference': '$surahNumber:$ayatNumber',
          });
        });
      }
    } catch (e) {
      print('Error fetching ayat details: $e');
    }
  }

  Future<void> removeBookmark(String reference) async {
    final activeUserBox = Hive.box(HiveConfig.activeUserBoxName);
    final userData = activeUserBox.get('activeUser');

    if (userData != null) {
      final userBox = Hive.box<UserModel>(HiveConfig.userBoxName);
      final user =
          userBox.values.firstWhere((u) => u.email == userData['email']);

      setState(() {
        user.bookmarks.remove(reference);
        bookmarkedAyatDetails
            .removeWhere((ayat) => ayat['reference'] == reference);
      });

      await user.save(); // Save the updated user data
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
        break;
      case 1:
        // Already on Terakhir Dibaca page
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
        title: Container(
          alignment: Alignment.center,
          child: Text(
            'Terakhir Dibaca',
            style: TextStyle(
              color: const Color(0xFF1DB954),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: bookmarkedAyatDetails.isEmpty
            ? Center(
                child: Text("Belum ada ayat yang dibaca",
                    style: TextStyle(color: Colors.white)))
            : ListView.builder(
                itemCount: bookmarkedAyatDetails.length,
                itemBuilder: (context, index) {
                  final ayatDetails = bookmarkedAyatDetails[index];
                  return Card(
                    color: const Color(0xFF191414),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Surah: ${ayatDetails['surahName']} (Ayat ${ayatDetails['number']})',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              ayatDetails['ar'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ayatDetails['tr'],
                            style: TextStyle(
                              color: const Color(0xFF1DB954),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ayatDetails['idn'],
                            style: TextStyle(
                              color: const Color(0xFF6AFF9F),
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  removeBookmark(ayatDetails['reference']);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: const Color(0xFF1DB954),
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
