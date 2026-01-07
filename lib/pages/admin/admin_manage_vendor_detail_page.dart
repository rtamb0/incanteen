import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incanteen/services/admin/admin_vendor_service.dart';

class AdminManageVendorDetailPage extends StatefulWidget {
  final String vendorId;

  const AdminManageVendorDetailPage({super.key, required this.vendorId});

  @override
  State<AdminManageVendorDetailPage> createState() =>
      _AdminManageVendorDetailPageState();
}

class _AdminManageVendorDetailPageState
    extends State<AdminManageVendorDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _vendorData;
  bool _editingVendor = false;

  late TextEditingController _vendorNameCtl;
  late TextEditingController _vendorLocationCtl;

  @override
  void initState() {
    super.initState();
    _vendorNameCtl = TextEditingController();
    _vendorLocationCtl = TextEditingController();
    _loadVendorData();
  }

  @override
  void dispose() {
    _vendorNameCtl.dispose();
    _vendorLocationCtl.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doc = await AdminVendorService().getVendorInfo(widget.vendorId);
      if (mounted) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          setState(() {
            _vendorData = data;
            _vendorNameCtl.text = (data?['storeName'] as String?) ?? '';
            _vendorLocationCtl.text = (data?['storeLocation'] as String?) ?? '';
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'Vendor store info not found';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveVendorInfo() async {
    try {
      await AdminVendorService().updateVendorInfo(
        widget.vendorId,
        name: _vendorNameCtl.text.trim(),
        location: _vendorLocationCtl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor info updated successfully')),
        );
        setState(() => _editingVendor = false);
        _loadVendorData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Details'),
        actions: [
          if (!_editingVendor && _vendorData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _editingVendor = true);
              },
              tooltip: 'Edit',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadVendorData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadVendorData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vendor Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              child: const Icon(
                                Icons.store,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _vendorData?['storeName'] as String? ??
                                        'N/A',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _vendorData?['storeLocation'] as String? ??
                                        'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Edit Mode
                    if (_editingVendor) ...[
                      const Text(
                        'Edit Vendor Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _vendorNameCtl,
                        decoration: InputDecoration(
                          labelText: 'Vendor Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.store),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vendorLocationCtl,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveVendorInfo,
                              child: const Text('Save Changes'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _editingVendor = false);
                                _loadVendorData();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      // View Mode
                      const Text(
                        'Vendor Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        label: 'Name',
                        value: _vendorData?['storeName'] as String? ?? 'N/A',
                      ),
                      _InfoCard(
                        label: 'Location',
                        value:
                            _vendorData?['storeLocation'] as String? ?? 'N/A',
                      ),
                      if (_vendorData?['createdAt'] != null)
                        _InfoCard(
                          label: 'Store Created',
                          value: _formatTimestamp(
                            _vendorData!['createdAt'] as Timestamp,
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Menu Items
                    const Text(
                      'Menu Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot>(
                      stream: AdminVendorService().getVendorMenus(
                        widget.vendorId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No menu items',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            final menuId = doc.id;
                            final name = data['name'] as String? ?? 'N/A';
                            final price = data['price'] as num? ?? 0;
                            final description =
                                data['description'] as String? ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Icon(
                                    Icons.restaurant,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (description.isNotEmpty)
                                      Text(
                                        description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Text('Edit Price'),
                                      onTap: () {
                                        _showEditPriceDialog(
                                          menuId,
                                          name,
                                          price.toDouble(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Info about limited access
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'As admin, you can only edit vendor name, location, and menu prices. '
                        'Menu names and descriptions are controlled by the vendor.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showEditPriceDialog(
    String menuId,
    String menuName,
    double currentPrice,
  ) {
    final controller = TextEditingController(text: currentPrice.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Menu Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Item: $menuName'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Price (Rp)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.local_atm),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice == null || newPrice < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
                return;
              }

              try {
                await AdminVendorService().updateMenuItemPrice(
                  widget.vendorId,
                  menuId,
                  newPrice,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Price updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update price: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
