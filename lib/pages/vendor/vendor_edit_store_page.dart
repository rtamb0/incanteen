import 'package:flutter/material.dart';
import 'package:incanteen/services/vendor/vendor_service.dart';

class VendorEditStorePage extends StatefulWidget {
  final Map<String, dynamic> storeData;

  const VendorEditStorePage({super.key, required this.storeData});

  @override
  State<VendorEditStorePage> createState() => _VendorEditStorePageState();
}

class _VendorEditStorePageState extends State<VendorEditStorePage> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();

  late TextEditingController _nameCtl;
  late TextEditingController _locationCtl;
  late TextEditingController _descriptionCtl;
  late TextEditingController _imageUrlCtl;
  late bool _isOpen;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.storeData['name'] ?? '');
    _locationCtl = TextEditingController(
      text: widget.storeData['location'] ?? '',
    );
    _descriptionCtl = TextEditingController(
      text: widget.storeData['description'] ?? '',
    );
    _imageUrlCtl = TextEditingController(
      text: widget.storeData['imageUrl'] ?? '',
    );
    _isOpen = widget.storeData['isOpen'] ?? true;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _locationCtl.dispose();
    _descriptionCtl.dispose();
    _imageUrlCtl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _vendorService.updateVendorStore(
        name: _nameCtl.text.trim(),
        location: _locationCtl.text.trim(),
        description: _descriptionCtl.text.trim(),
        imageUrl: _imageUrlCtl.text.trim(),
        isOpen: _isOpen,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update store: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Store Info')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Name
                TextFormField(
                  controller: _nameCtl,
                  decoration: InputDecoration(
                    labelText: 'Store Name',
                    hintText: 'e.g., John\'s Restaurant',
                    prefixIcon: const Icon(Icons.store),
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

                // Location
                TextFormField(
                  controller: _locationCtl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Location / Address',
                    hintText: 'e.g., Kantin B2',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Location is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Please provide a valid location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionCtl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Tell customers about your store...',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Image URL
                TextFormField(
                  controller: _imageUrlCtl,
                  decoration: InputDecoration(
                    labelText: 'Image URL (Optional)',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: const Icon(Icons.image),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final uri = Uri.tryParse(value.trim());
                      if (uri == null || !uri.hasScheme) {
                        return 'Please enter a valid URL';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Store Status Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOpen ? Icons.store : Icons.store_outlined,
                        color: _isOpen ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Store Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _isOpen ? 'Currently Open' : 'Currently Closed',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isOpen ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOpen,
                        onChanged: (value) {
                          setState(() {
                            _isOpen = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
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
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
