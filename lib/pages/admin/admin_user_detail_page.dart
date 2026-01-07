import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:incanteen/services/admin/admin_service.dart';

class AdminUserDetailPage extends StatefulWidget {
  final String userId;

  const AdminUserDetailPage({super.key, required this.userId});

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doc = await AdminService().getUserById(widget.userId);
      if (mounted) {
        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>?;
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'User not found';
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

  Future<void> _updateRole(String newRole) async {
    try {
      await AdminService().updateUserRole(widget.userId, newRole);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Role updated to $newRole')));
        _loadUserData(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
      }
    }
  }

  Future<void> _deleteUser() async {
    // Prevent self-deletion
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prevent admin from deleting superadmin accounts
    final targetUserRole = _userData?['role'] as String?;
    if (targetUserRole == 'superadmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete superadmin accounts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this user?\n\n'
          'This will remove their data from the database. '
          'They will not be able to use the app anymore.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService().deleteUser(widget.userId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
        }
      }
    }
  }

  void _showRoleChangeDialog() async {
    // Prevent admin from changing their own role
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot change your own role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prevent admin from modifying superadmin or admin accounts
    final targetUserRole = _userData?['role'] as String?;
    if (targetUserRole == 'superadmin' || targetUserRole == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to modify admin or superadmin accounts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if current user is superadmin
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .get();
    final isSuperAdmin = currentUserDoc.data()?['role'] == 'superadmin';

    final currentRole = _userData?['role'] as String? ?? 'customer';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Customer'),
              value: 'customer',
              groupValue: currentRole,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) _updateRole(value);
              },
            ),
            RadioListTile<String>(
              title: const Text('Vendor'),
              value: 'vendor',
              groupValue: currentRole,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) _updateRole(value);
              },
            ),
            if (isSuperAdmin)
              RadioListTile<String>(
                title: const Text('Admin'),
                value: 'admin',
                groupValue: currentRole,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value != null) _updateRole(value);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteUser,
            tooltip: 'Delete User',
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
                    onPressed: _loadUserData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: _getRoleColor(
                                _userData?['role'] as String? ?? 'unknown',
                              ).withOpacity(0.2),
                              child: Icon(
                                _getRoleIcon(
                                  _userData?['role'] as String? ?? 'unknown',
                                ),
                                size: 40,
                                color: _getRoleColor(
                                  _userData?['role'] as String? ?? 'unknown',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userData?['displayName'] as String? ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userData?['email'] as String? ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(
                                      _userData?['role'] as String? ??
                                          'unknown',
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    (_userData?['role'] as String? ?? 'unknown')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getRoleColor(
                                        _userData?['role'] as String? ??
                                            'unknown',
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // User Details
                    const Text(
                      'User Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _InfoTile(label: 'User ID', value: widget.userId),
                    _InfoTile(
                      label: 'Display Name',
                      value: _userData?['displayName'] as String? ?? 'N/A',
                    ),
                    _InfoTile(
                      label: 'Email',
                      value: _userData?['email'] as String? ?? 'N/A',
                    ),
                    _InfoTile(
                      label: 'Role',
                      value: _userData?['role'] as String? ?? 'N/A',
                    ),
                    if (_userData?['createdAt'] != null)
                      _InfoTile(
                        label: 'Created At',
                        value: _formatTimestamp(
                          _userData!['createdAt'] as Timestamp,
                        ),
                      ),
                    if (_userData?['updatedAt'] != null)
                      _InfoTile(
                        label: 'Updated At',
                        value: _formatTimestamp(
                          _userData!['updatedAt'] as Timestamp,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Actions
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showRoleChangeDialog,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Change Role'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _deleteUser,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'superadmin':
        return Colors.redAccent;
      case 'admin':
        return Colors.purple;
      case 'vendor':
        return Colors.blue;
      case 'customer':
        return Colors.orange;
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
      case 'vendor':
        return Icons.store;
      case 'customer':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
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
