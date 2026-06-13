import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_helper.dart';
import '../models/caregiver.dart';

enum UserRole { patient, caregiver }

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();
  
  // Add default constructor for dependency injection
  AuthService();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _currentUserIdKey = 'current_user_id';
  static const String _currentUserRoleKey = 'current_user_role';
  static const String _rememberMeKey = 'remember_me';
  static const String _autoLoginKey = 'auto_login';

  UserRole _currentRole = UserRole.patient;
  UserRole get currentRole => _currentRole;

  bool get isCaregiver => _currentRole == UserRole.caregiver;

  // Password hashing using PBKDF2
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate a random salt
  String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  // Register a new user
  Future<UserRegistrationResult> register({
    required String name,
    required String email,
    required String password,
    required int age,
    bool rememberMe = false,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        return UserRegistrationResult(
          success: false,
          message: 'An account with this email already exists',
        );
      }

      // Validate inputs
      if (name.trim().isEmpty) {
        return UserRegistrationResult(
          success: false,
          message: 'Name cannot be empty',
        );
      }

      if (!_isValidEmail(email)) {
        return UserRegistrationResult(
          success: false,
          message: 'Please enter a valid email address',
        );
      }

      if (password.length < 6) {
        return UserRegistrationResult(
          success: false,
          message: 'Password must be at least 6 characters long',
        );
      }

      if (age < 18 || age > 120) {
        return UserRegistrationResult(
          success: false,
          message: 'Please enter a valid age',
        );
      }

      // Generate salt and hash password
      final salt = generateSalt();
      final passwordHash = hashPassword(password, salt);

      // Create user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email.trim().toLowerCase(),
        name: name.trim(),
        age: age,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isGuest: false,
        isActive: true,
      );

      await _db.createUser(user, passwordHash, salt);

      // Save login state if remember me is checked
      if (rememberMe) {
        await _saveLoginState(user.id, rememberMe: true);
      }

      return UserRegistrationResult(
        success: true,
        message: 'Account created successfully',
        user: user,
      );
    } catch (e) {
      return UserRegistrationResult(
        success: false,
        message: 'An error occurred during registration: ${e.toString()}',
      );
    }
  }

  // Login user
  Future<UserLoginResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Get user by email
      final user = await _db.getUserByEmail(email.trim().toLowerCase());
      if (user == null) {
        return UserLoginResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Get user credentials
      final credentials = await _db.getUserCredentials(user.id);
      if (credentials == null) {
        return UserLoginResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Verify password
      final passwordHash = hashPassword(password, credentials['salt']!);
      if (passwordHash != credentials['passwordHash']) {
        return UserLoginResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Check if user is active
      if (!user.isActive) {
        return UserLoginResult(
          success: false,
          message: 'This account has been deactivated',
        );
      }

      // Update last login
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _db.updateUser(updatedUser);

      // Save login state
      await _saveLoginState(user.id, rememberMe: rememberMe);

      return UserLoginResult(
        success: true,
        message: 'Login successful',
        user: updatedUser,
      );
    } catch (e) {
      return UserLoginResult(
        success: false,
        message: 'An error occurred during login: ${e.toString()}',
      );
    }
  }

  // Login caregiver
  Future<CaregiverLoginResult> loginCaregiver({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Get caregiver by email
      final caregiverMap = await _db.getCaregiverByEmail(email.trim().toLowerCase());
      if (caregiverMap == null) {
        return CaregiverLoginResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      final caregiver = Caregiver.fromMap(caregiverMap);

      // Get caregiver credentials
      final credentials = await _db.getCaregiverCredentials(caregiver.id);
      if (credentials == null) {
        return CaregiverLoginResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Verify password
      final passwordHash = hashPassword(password, credentials['salt']!);
      if (passwordHash != credentials['passwordHash']) {
        return CaregiverLoginResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Save login state
      await _saveLoginState(caregiver.id, role: UserRole.caregiver, rememberMe: rememberMe);
      _currentRole = UserRole.caregiver;

      return CaregiverLoginResult(
        success: true,
        message: 'Login successful',
        caregiver: caregiver,
      );
    } catch (e) {
      return CaregiverLoginResult(
        success: false,
        message: 'An error occurred during login: ${e.toString()}',
      );
    }
  }

  // Switch role for demo purposes
  Future<void> switchRole(UserRole newRole) async {
    _currentRole = newRole;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserRoleKey, newRole.toString());
  }

  // Continue as guest
  Future<UserLoginResult> continueAsGuest() async {
    try {
      // Create a guest user
      final user = User(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        email: 'guest@memoriae.app',
        name: 'Guest User',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isGuest: true,
        isActive: true,
      );

      await _db.createUser(user, null, null);
      await _saveLoginState(user.id, rememberMe: false);

      return UserLoginResult(
        success: true,
        message: 'Continuing as guest',
        user: user,
      );
    } catch (e) {
      return UserLoginResult(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  // Check if user is logged in
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserIdKey);
      
      if (userId == null) return null;
      
      final user = await _db.getUserById(userId);
      if (user != null) {
        _currentRole = UserRole.patient;
        final roleStr = prefs.getString(_currentUserRoleKey);
        if (roleStr != null) {
          _currentRole = UserRole.values.firstWhere(
            (e) => e.toString() == roleStr,
            orElse: () => UserRole.patient,
          );
        }
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  // Get current caregiver
  Future<Caregiver?> getCurrentCaregiver() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserIdKey);
      
      if (userId == null) return null;
      
      final caregiverMap = await _db.getCaregiverById(userId);
      if (caregiverMap != null) {
        return Caregiver.fromMap(caregiverMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check auto-login
  Future<bool> shouldAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoLoginKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserIdKey);
      await prefs.remove(_currentUserRoleKey);
      await prefs.remove('user_id');
      await prefs.remove('is_logged_in');
      await prefs.remove(_autoLoginKey);
      await prefs.remove(_rememberMeKey);
      _currentRole = UserRole.patient;
    } catch (e) {
      // Ignore errors during logout
    }
  }

  // Change password
  Future<PasswordChangeResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = await _db.getUserById(userId);
      if (user == null || user.isGuest) {
        return PasswordChangeResult(
          success: false,
          message: 'User not found',
        );
      }

      // Verify current password
      final credentials = await _db.getUserCredentials(userId);
      if (credentials == null) {
        return PasswordChangeResult(
          success: false,
          message: 'Invalid credentials',
        );
      }

      final currentPasswordHash = hashPassword(currentPassword, credentials['salt']!);
      if (currentPasswordHash != credentials['passwordHash']) {
        return PasswordChangeResult(
          success: false,
          message: 'Current password is incorrect',
        );
      }

      // Validate new password
      if (newPassword.length < 6) {
        return PasswordChangeResult(
          success: false,
          message: 'New password must be at least 6 characters long',
        );
      }

      // Generate new salt and hash
      final newSalt = generateSalt();
      final newPasswordHash = hashPassword(newPassword, newSalt);

      // Update password
      await _db.updateUserPassword(userId, newPasswordHash, newSalt);

      return PasswordChangeResult(
        success: true,
        message: 'Password changed successfully',
      );
    } catch (e) {
      return PasswordChangeResult(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  // Delete account
  Future<bool> deleteAccount(String userId) async {
    try {
      await _db.deleteUser(userId);
      await logout();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Private helper methods
  Future<void> _saveLoginState(String userId, {UserRole role = UserRole.patient, required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
    await prefs.setString(_currentUserRoleKey, role.toString());
    await prefs.setString('user_id', userId); // For splash screen check
    await prefs.setBool('is_logged_in', true); // For splash screen check
    await prefs.setBool(_rememberMeKey, rememberMe);
    await prefs.setBool(_autoLoginKey, rememberMe);
    _currentRole = role;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

// Result classes
class UserRegistrationResult {
  final bool success;
  final String message;
  final User? user;

  UserRegistrationResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class UserLoginResult {
  final bool success;
  final String message;
  final User? user;

  UserLoginResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class PasswordChangeResult {
  final bool success;
  final String message;

  PasswordChangeResult({
    required this.success,
    required this.message,
  });
}

class CaregiverLoginResult {
  final bool success;
  final String message;
  final Caregiver? caregiver;

  CaregiverLoginResult({
    required this.success,
    required this.message,
    this.caregiver,
  });
}
