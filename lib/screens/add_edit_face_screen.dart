import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/familiar_face.dart';
import '../services/familiar_face_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';
import '../widgets/rounded_image_picker.dart';

class AddEditFaceScreen extends StatefulWidget {
  static const routeName = '/add-edit-face';

  const AddEditFaceScreen({super.key});

  @override
  State<AddEditFaceScreen> createState() => _AddEditFaceScreenState();
}

class _AddEditFaceScreenState extends State<AddEditFaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  String? _photoPath;
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _faceId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is FamiliarFace) {
        _populateForm(args);
      }
    });
  }

  void _populateForm(FamiliarFace face) {
    setState(() {
      _isEditMode = true;
      _faceId = face.id;
      _userId = face.userId;
      _nameController.text = face.name;
      _relationController.text = face.relation;
      _phoneController.text = face.phoneNumber ?? '';
      _emailController.text = face.email ?? '';
      _notesController.text = face.notes ?? '';
      _photoPath = face.photoPath;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profileService = context.read<ProfileService>();
      final faceService = context.read<FamiliarFaceService>();

      final face = FamiliarFace(
        id: _faceId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId ?? profileService.profile!.id,
        name: _nameController.text.trim(),
        relation: _relationController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        photoPath: _photoPath,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: _isEditMode ? DateTime.now() : DateTime.now(),
      );

      if (_isEditMode) {
        await faceService.updateFace(face);
      } else {
        await faceService.addFace(face);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving face: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final themeService = Provider.of<ThemeService>(context, listen: false);
      final isBlackMinimalism =
          themeService.themeMode == AppThemeMode.blackMinimalism;
      final faceService = context.read<FamiliarFaceService>();
      final imagePath = await showModalBottomSheet<String?>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Container(
            color: isBlackMinimalism ? const Color(0xFF1A1A1A) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: isBlackMinimalism ? Colors.white70 : null,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                  onTap: () async {
                    final path = await faceService.pickImage(fromCamera: false);
                    Navigator.of(ctx).pop(path);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: isBlackMinimalism ? Colors.white70 : null,
                  ),
                  title: Text(
                    'Take a Photo',
                    style: TextStyle(
                      color: isBlackMinimalism ? Colors.white : null,
                    ),
                  ),
                  onTap: () async {
                    final path = await faceService.pickImage(fromCamera: true);
                    Navigator.of(ctx).pop(path);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      if (imagePath != null && mounted) {
        setState(() => _photoPath = imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final isBlackMinimalism =
        themeService.themeMode == AppThemeMode.blackMinimalism;

    return Scaffold(
      backgroundColor: isBlackMinimalism ? Colors.black : null,
      appBar: AppBar(
        backgroundColor: isBlackMinimalism ? Colors.black : null,
        elevation: isBlackMinimalism ? 0 : null,
        iconTheme: IconThemeData(
          color: isBlackMinimalism ? Colors.white : null,
        ),
        title: Text(
          _isEditMode ? 'Edit Contact' : 'Add New Contact',
          style: TextStyle(color: isBlackMinimalism ? Colors.white : null),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.check,
                color: isBlackMinimalism ? Colors.white : null,
              ),
              onPressed: _isLoading ? null : _submitForm,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: RoundedImagePicker(
                        imagePath: _photoPath,
                        onImagePicked: _pickImage,
                        radius: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        enabledBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              )
                            : null,
                        focusedBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _relationController,
                      style: TextStyle(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Relation',
                        labelStyle: TextStyle(
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        hintText: 'e.g., Daughter, Son, Friend',
                        hintStyle: TextStyle(
                          color: isBlackMinimalism ? Colors.white24 : null,
                        ),
                        prefixIcon: Icon(
                          Icons.group,
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        enabledBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              )
                            : null,
                        focusedBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please specify your relationship';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        labelStyle: TextStyle(
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        prefixIcon: Icon(
                          Icons.phone,
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        enabledBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              )
                            : null,
                        focusedBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email (Optional)',
                        labelStyle: TextStyle(
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        prefixIcon: Icon(
                          Icons.email,
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        enabledBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              )
                            : null,
                        focusedBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      style: TextStyle(
                        color: isBlackMinimalism ? Colors.white : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: TextStyle(
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        prefixIcon: Icon(
                          Icons.notes,
                          color: isBlackMinimalism ? Colors.white70 : null,
                        ),
                        enabledBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              )
                            : null,
                        focusedBorder: isBlackMinimalism
                            ? const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isBlackMinimalism
                            ? Colors.white
                            : null,
                        foregroundColor: isBlackMinimalism
                            ? Colors.black
                            : null,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isBlackMinimalism
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            )
                          : Text(
                              _isEditMode ? 'Update Contact' : 'Add Contact',
                            ),
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: isBlackMinimalism ? Colors.white38 : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
