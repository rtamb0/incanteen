import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class VendorEditProfilePage extends StatefulWidget {
  final String? initialPhoneNumber;
  const VendorEditProfilePage({super.key, this.initialPhoneNumber});

  @override
  State<VendorEditProfilePage> createState() => _VendorEditProfilePageState();
}

class _VendorEditProfilePageState extends State<VendorEditProfilePage> {
  late TextEditingController _displayNameCtl;
  late TextEditingController _phoneCtl;
  File? _selectedImage;
  bool _isLoading = false;
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _displayNameCtl = TextEditingController(text: user?.displayName ?? '');
    _phoneCtl = TextEditingController(text: widget.initialPhoneNumber ?? '');

    // Fallback: if not provided, load from Firestore
    if ((widget.initialPhoneNumber == null ||
            (widget.initialPhoneNumber ?? '').isEmpty) &&
        user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((
        doc,
      ) {
        if (doc.exists && doc.data()?['phoneNumber'] != null) {
          _phoneCtl.text = doc.data()!['phoneNumber'] ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _displayNameCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        final cropped = await _cropToSquare(pickedFile.path);
        if (cropped != null) {
          setState(() {
            _selectedImage = cropped;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<File?> _cropToSquare(String path) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 400,
        maxHeight: 400,
        compressQuality: 85,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop photo',
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.black,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop photo', aspectRatioLockEnabled: true),
        ],
      );
      if (cropped == null) return null;
      return File(cropped.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cropping image: $e')));
      }
      return null;
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_selectedImage == null) return null;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(user.uid)
          .child('avatar.jpg');

      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update display name
      if (_displayNameCtl.text.trim() != user.displayName) {
        await user.updateDisplayName(_displayNameCtl.text.trim());
      }

      // Update phone number in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phoneNumber': _phoneCtl.text.trim(),
      }, SetOptions(merge: true));

      // Upload profile picture if selected
      if (_selectedImage != null) {
        final imageUrl = await _uploadImageToFirebase();
        if (imageUrl != null) {
          await user.updatePhotoURL(imageUrl);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hasPhoto =
        _selectedImage != null || ((user?.photoURL ?? '').isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              const Text(
                'Profile Picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : null)
                                as ImageProvider?,
                      backgroundColor: Colors.blue.shade100,
                      child: _selectedImage == null && user?.photoURL == null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.person,
                                    size: 48,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(height: 0),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'Upload profile picture',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            hasPhoto ? Icons.edit : Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Display Name
              const Text(
                'Display Name',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameCtl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Display name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Phone Number
              const Text(
                'Phone Number',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtl,
                decoration: InputDecoration(
                  hintText: '081234567890',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
