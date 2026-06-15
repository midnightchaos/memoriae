import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/user.dart';

class ProfileService extends ChangeNotifier {
  static const _key = 'user_profile';
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileData = prefs.getString(_key);

      if (profileData != null) {
        _profile = UserProfile.fromMap(
          Map<String, dynamic>.from(json.decode(profileData)),
        );
      } else {
        // Create a default profile if none exists
        _profile = UserProfile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'User',
          email: '',
          caregiverAccess: false,
        );
        await save(_profile!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> save(UserProfile profile) async {
    try {
      _profile = profile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(profile.toMap()));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving profile: $e');
      rethrow;
    }
  }

  Future<void> updateName(String name) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(name: name);
    await save(_profile!);
  }

  Future<void> setCaregiverAccess(bool allowed) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(caregiverAccess: allowed);
    await save(_profile!);
  }

  Future<void> syncWithUser(User user) async {
    final updatedProfile = UserProfile(
      id: user.id,
      name: user.name,
      email: user.email,
      age: user.age,
      caregiverAccess: _profile?.caregiverAccess ?? false,
      linkedCaregiverId: _profile?.linkedCaregiverId,
    );
    await save(updatedProfile);
  }
}
