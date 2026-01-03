import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incanteen/services/auth/auth_service.dart';
import 'package:incanteen/services/admin/admin_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  
  // Cache for vendor document existence to avoid repeated queries
  final Map<String, bool> _vendorDocCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (!context.mounted) return;
      // Auth state listener in main.dart will handle navigation
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    }
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> userData,
      String userId) {
    final displayNameController =
        TextEditingController(text: userData['displayName'] ?? '');
    final emailController =
        TextEditingController(text: userData['email'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDisplayName = displayNameController.text.trim();
              final newEmail = emailController.text.trim();

              if (newDisplayName.isEmpty || newEmail.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Display name and email cannot be empty'),
                  ),
                );
                return;
              }

              // Validate email format
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(newEmail)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address'),
                  ),
                );
                return;
              }

              try {
                // Update display name if changed
                if (newDisplayName != userData['displayName']) {
                  await _adminService.updateUserDisplayName(
                    userId,
                    newDisplayName,
                  );
                }

                // Update email if changed
                if (newEmail != userData['email']) {
                  await _adminService.updateUserEmail(userId, newEmail);
                }

                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User updated successfully'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating user: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.getUsersByRole(role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading users: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No ${role}s found'),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final userId = userDoc.id;

            // Get or fetch vendor document existence status
            bool? hasVendorDoc;
            if (role == 'vendor') {
              if (_vendorDocCache.containsKey(userId)) {
                hasVendorDoc = _vendorDocCache[userId];
              } else {
                // Will be fetched asynchronously below
                hasVendorDoc = null;
              }
            }

            return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (userData['displayName'] ?? 'U')[0].toUpperCase(),
                      ),
                    ),
                    title: Text(userData['displayName'] ?? 'No name'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userData['email'] ?? 'No email'),
                        Text(
                          'Role: ${userData['role'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (role == 'vendor')
                          FutureBuilder<bool>(
                            future: hasVendorDoc != null
                                ? Future.value(hasVendorDoc)
                                : _adminService.vendorDocumentExists(userId).then(
                                    (exists) {
                                      // Cache the result
                                      _vendorDocCache[userId] = exists;
                                      return exists;
                                    },
                                  ),
                            builder: (context, snapshot) {
                              final exists = snapshot.data ?? false;
                              return Text(
                                exists ? 'Vendor doc: ✓' : 'Vendor doc: ✗',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: exists ? Colors.green : Colors.red,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEditUserDialog(context, userData, userId),
                    ),
                  ),
                );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Customers', icon: Icon(Icons.people)),
            Tab(text: 'Vendors', icon: Icon(Icons.store)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings,
                    size: 40, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  'Welcome, ${user?.displayName ?? user?.email ?? 'Admin'}!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList('customer'),
                _buildUsersList('vendor'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
