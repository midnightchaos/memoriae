import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:convert';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'db_encryption_key';
  static const _ivName = 'db_encryption_iv';
  
  // Generate a random encryption key if one doesn't exist
  static Future<encrypt.Key> getEncryptionKey() async {
    String? keyString = await _storage.read(key: _keyName);
    
    if (keyString == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      keyString = base64Url.encode(values);
      await _storage.write(key: _keyName, value: keyString);
    }
    
    return encrypt.Key(base64Url.decode(keyString));
  }

  // Generate a random IV if one doesn't exist
  static Future<encrypt.IV> getIV() async {
    String? ivString = await _storage.read(key: _ivName);
    
    if (ivString == null) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      ivString = base64Url.encode(values);
      await _storage.write(key: _ivName, value: ivString);
    }
    
    return encrypt.IV(base64Url.decode(ivString));
  }

  // Encrypt a string
  static Future<String> encryptString(String plaintext) async {
    if (plaintext.isEmpty) return plaintext;
    
    try {
      final key = await getEncryptionKey();
      final iv = await getIV();
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      return base64Url.encode(encrypted.bytes);
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  // Decrypt a string
  static Future<String> decryptString(String encrypted) async {
    if (encrypted.isEmpty) return encrypted;
    
    try {
      final key = await getEncryptionKey();
      final iv = await getIV();
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decrypt(
        encrypt.Encrypted(base64Url.decode(encrypted)),
        iv: iv,
      );
      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }
}
