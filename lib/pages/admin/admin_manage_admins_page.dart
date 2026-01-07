import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incanteen/services/admin/admin_service.dart';
import 'package:incanteen/routes/routes_constants.dart';

class AdminManageAdminsPage extends StatefulWidget {
  const AdminManageAdminsPage({super.key});

  @override
  State<AdminManageAdminsPage> createState() => _AdminManageAdminsPageState();
}

class _AdminManageAdminsPageState extends State<AdminManageAdminsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Trigger rebuild to refresh stream
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Admin list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AdminService().getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No admins found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter admins and superadmins
                final admins = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] as String?;

                  // Only show admin and superadmin
                  if (role != 'admin' && role != 'superadmin') {
                    return false;
                  }

                  // Filter by search query
                  if (_searchQuery.isEmpty) return true;

                  final displayName = (data['displayName'] as String? ?? '')
                      .toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();

                  return displayName.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (admins.isEmpty) {
                  return Center(
                    child: Text(
                      'No admins match your search',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: admins.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ).copyWith(bottom: 80),
                  itemBuilder: (context, index) {
                    final doc = admins[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final userId = doc.id;
                    final displayName = data['displayName'] as String? ?? 'N/A';
                    final email = data['email'] as String? ?? 'N/A';
                    final role = data['role'] as String? ?? 'unknown';
                    final createdAt = data['createdAt'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(role).withOpacity(0.2),
                          child: Icon(
                            _getRoleIcon(role),
                            color: _getRoleColor(role),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(
                                        role,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getRoleColor(role),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (createdAt != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Joined: ${_formatDate(createdAt)}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RoutesConstants.adminUserDetailRoute,
                            arguments: {'userId': userId},
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'superadmin':
        return Colors.redAccent;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'superadmin':
        return Icons.workspace_premium;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
