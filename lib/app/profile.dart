import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quran/app/editProfile.dart';
import 'package:quran/app/home.dart';

import 'package:quran/app/terakhirdibaca.dart';

import 'package:quran/database/hive_config.dart';
import 'package:quran/database/user_model.dart';
import 'package:quran/start%20login/start.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  UserModel? activeUser;

  @override
  void initState() {
    super.initState();
    _loadActiveUser();
  }

  Future<void> _loadActiveUser() async {
    final userData = await HiveConfig.getActiveUser();
    if (userData != null && mounted) {
      setState(() {
        activeUser = UserModel(
          username: userData['username'],
          email: userData['email'],
          password: '',
          photoPath: userData['photoPath'],
        );
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfile()),
    );

    // Jika ada perubahan, reload data user
    if (result != null && mounted) {
      _loadActiveUser(); // Reload data setelah edit
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
            'Profil',
            style: TextStyle(
              color: const Color(0xFF1DB954),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: activeUser == null
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Image and Info
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: activeUser!.photoPath != null
                              ? FileImage(File(activeUser!.photoPath!))
                              : const AssetImage('images/default_profile.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          activeUser!.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeUser!.email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Row for buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _navigateToEditProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF176D35),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 45, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await HiveConfig.logout();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Start()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB22222),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Set the Profile tab as active
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: const Color(0xFF1DB954),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_add), label: 'Terakhir Dibaca'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TerakhirDibaca()),
            );
          }
        },
      ),
    );
  }
}
