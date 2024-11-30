// lib/database/hive_config.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'user_model.dart';

class HiveConfig {
  static const String userBoxName = 'users';
  static const String activeUserBoxName = 'activeUser';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox(activeUserBoxName);
  }

  static String encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  static Future<bool> registerUser(UserModel user) async {
    try {
      final box = Hive.box<UserModel>(userBoxName);

      // Check if email already exists
      final existingUser = box.values.any((u) => u.email == user.email);
      if (existingUser) {
        return false;
      }

      // Encrypt password before saving
      user.password = encryptPassword(user.password);
      print('Encrypted Password: ${user.password}');
      await box.add(user);
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  static Future<UserModel?> loginUser(String email, String password) async {
    try {
      final box = Hive.box<UserModel>(userBoxName);
      final encryptedPassword = encryptPassword(password);
      print('Encrypted Password for Login: $encryptedPassword');

      final user = box.values.firstWhere(
        (user) => user.email == email && user.password == encryptedPassword,
      );

      if (user != null) {
        // Save active user
        final activeUserBox = Hive.box(activeUserBoxName);
        await activeUserBox.put('activeUser', {
          'username': user.username,
          'email': user.email,
          'photoPath': user.photoPath,
        });
      }

      return user;
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getActiveUser() async {
    final activeUserBox = Hive.box(activeUserBoxName);
    return activeUserBox.get('activeUser');
  }

  static Future<void> logout() async {
    final activeUserBox = Hive.box(activeUserBoxName);
    await activeUserBox.delete('activeUser');
  }

  static Future<void> updateUser(
      String email, String username, String? photoPath) async {
    try {
      final box = Hive.box<UserModel>(userBoxName);
      final user = box.values.firstWhere((u) => u.email == email);

      user.username = username;
      if (photoPath != null) {
        user.photoPath = photoPath;
      }
      await user.save();

      // Update active user
      final activeUserBox = Hive.box(activeUserBoxName);
      await activeUserBox.put('activeUser', {
        'username': username,
        'email': email,
        'photoPath': photoPath,
      });
    } catch (e) {
      print('Error updating user: $e');
    }
  }
}
