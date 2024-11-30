// lib/database/user_model.dart
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String email;

  @HiveField(2)
  String password;

  @HiveField(3)
  String? photoPath;

  @HiveField(4)
  List<String> bookmarks; // List to store bookmarked ayats

  UserModel({
    required this.username,
    required this.email,
    required this.password,
    this.photoPath,
    List<String>? bookmarks,
  }) : bookmarks = bookmarks ?? [];

  set lastReadVerse(Map<String, String> lastReadVerse) {}
}
