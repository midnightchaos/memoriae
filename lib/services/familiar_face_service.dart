import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/familiar_face.dart';
import 'database_helper.dart';

class FamiliarFaceService with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _imagePicker = ImagePicker();

  List<FamiliarFace> _faces = [];
  List<FamiliarFace> get faces => _faces;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Safely notify listeners, deferring if called during a build phase.
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Load all familiar faces for a user
  Future<void> loadFaces(String userId) async {
    _isLoading = true;
    _safeNotify();

    try {
      _faces = await _dbHelper.getFamiliarFaces(userId);
    } catch (e) {
      debugPrint('Error loading familiar faces: $e');
      _faces = [];
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // Search familiar faces
  Future<List<FamiliarFace>> searchFaces(String userId, String query) async {
    try {
      return await _dbHelper.searchFamiliarFaces(userId, query);
    } catch (e) {
      debugPrint('Error searching familiar faces: $e');
      return [];
    }
  }

  // Add a new familiar face
  Future<FamiliarFace> addFace(FamiliarFace face) async {
    try {
      final newFace = await _dbHelper.createFamiliarFace(face);
      await loadFaces(face.userId); // Refresh the list
      return newFace;
    } catch (e) {
      debugPrint('Error adding familiar face: $e');
      rethrow;
    }
  }

  // Update an existing familiar face
  Future<void> updateFace(FamiliarFace face) async {
    try {
      await _dbHelper.updateFamiliarFace(face);
      await loadFaces(face.userId); // Refresh the list
    } catch (e) {
      debugPrint('Error updating familiar face: $e');
      rethrow;
    }
  }

  // Delete a familiar face
  Future<void> deleteFace(String faceId, String userId) async {
    try {
      await _dbHelper.deleteFamiliarFace(faceId);
      await loadFaces(userId); // Refresh the list
    } catch (e) {
      debugPrint('Error deleting familiar face: $e');
      rethrow;
    }
  }

  // Pick an image from gallery or camera
  Future<String?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Save the image to app's documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'face_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedImage = await File(
          pickedFile.path,
        ).copy('${appDir.path}/$fileName');
        return savedImage.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
