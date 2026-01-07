import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:incanteen/services/auth/auth_service.dart';

class VendorSetupPage extends StatefulWidget {
  const VendorSetupPage({super.key});

  @override
  State<VendorSetupPage> createState() => _VendorSetupPageState();
}

class _VendorSetupPageState extends State<VendorSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _vendorNameCtl = TextEditingController();
  final _imagePicker = ImagePicker();
  
  String _selectedLocation = 'Kantin B1';
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _vendorNameCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        // Crop the image with 4:3 aspect ratio
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Store Image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.ratio4x3,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Store Image',
              aspectRatioLockDimensionSwapEnabled: true,
              resetButtonHidden: false,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() => _selectedImage = File(croppedFile.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImageToFirebase(String userId) async {
    if (_selectedImage == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'store_$timestamp.jpg';
      final ref = FirebaseStorage.instance
          .ref('vendors')
          .child(userId)
          .child(fileName);

      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToFirebase(user.uid);
      }

      // Create vendor store info
      await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
        'name': _vendorNameCtl.text.trim(),
        'location': _selectedLocation,
        'description': '',
        'imageUrl': imageUrl ?? '',
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark vendor as setup complete
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'vendorSetupComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (mounted) {
        // Trigger role refresh and navigate
        AuthService.roleRefreshNotifier.value++;
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to setup vendor: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Vendor Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.store, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Set Up Your Vendor Store',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Complete your vendor profile to start selling',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _vendorNameCtl,
                        decoration: InputDecoration(
                          labelText: 'Store Name',
                          hintText: 'e.g., John\'s Restaurant',
                          prefixIcon: const Icon(Icons.storefront),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Store name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Store name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedLocation,
                        decoration: InputDecoration(
                          labelText: 'Store Location',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Kantin B1',
                            child: Text('Kantin B1'),
                          ),
                          DropdownMenuItem(
                            value: 'Kantin B2',
                            child: Text('Kantin B2'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLocation = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Location is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Image picker section
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.withOpacity(0.05),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                      color: Colors.grey.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tap to upload store image',
                                      style: TextStyle(
                                        color: Colors.grey.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '(Optional)',
                                      style: TextStyle(
                                        color: Colors.grey.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Remove image'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Complete Setup'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
