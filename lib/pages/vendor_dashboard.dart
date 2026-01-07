import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incanteen/services/auth/auth_service.dart';
import 'package:incanteen/services/vendor/vendor_service.dart';
import 'package:incanteen/pages/vendor/vendor_edit_store_page.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  final _vendorService = VendorService();

  Future<void> _signOut(BuildContext context) async {
    if (!await AuthService().confirmSignOut(context)) return;
    try {
      await AuthService().signOut();
      if (!context.mounted) return;
      // Auth state listener in main.dart will handle navigation
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
    }
  }

  Future<void> _toggleStoreStatus(bool currentStatus) async {
    try {
      await _vendorService.toggleStoreStatus(!currentStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus ? 'Store is now Open' : 'Store is now Closed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  Future<void> _editStoreInfo(Map<String, dynamic> storeData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorEditStorePage(storeData: storeData),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store info updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _vendorService.getVendorStoreStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading store: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Store information not found'));
          }

          final storeData = snapshot.data!.data() as Map<String, dynamic>;
          final storeName = storeData['name'] ?? 'My Store';
          final location = storeData['location'] ?? 'No location set';
          final description = storeData['description'] ?? '';
          final imageUrl = storeData['imageUrl'] ?? '';
          final isOpen = storeData['isOpen'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            user?.displayName ?? user?.email ?? 'Vendor',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Store Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Store Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editStoreInfo(storeData),
                              tooltip: 'Edit Store Info',
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Store Name
                        _buildInfoRow(Icons.store, 'Store Name', storeName),
                        const SizedBox(height: 12),

                        // Location
                        _buildInfoRow(Icons.location_on, 'Location', location),
                        const SizedBox(height: 12),

                        // Description
                        if (description.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.description,
                            'Description',
                            description,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Image URL
                        if (imageUrl.isNotEmpty) ...[
                          _buildInfoRow(Icons.image, 'Image URL', imageUrl),
                          const SizedBox(height: 12),
                        ],

                        // Store Status
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOpen ? Icons.store : Icons.store_outlined,
                                color: isOpen ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Store Status',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      isOpen ? 'Open' : 'Closed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOpen
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isOpen,
                                onChanged: (value) =>
                                    _toggleStoreStatus(isOpen),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      icon: Icons.restaurant_menu,
                      title: 'Manage Menu',
                      subtitle: 'Coming soon',
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.receipt_long,
                      title: 'Orders',
                      subtitle: 'Coming soon',
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.analytics,
                      title: 'Analytics',
                      subtitle: 'Coming soon',
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.settings,
                      title: 'Settings',
                      subtitle: 'Coming soon',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
