import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incanteen/services/admin/admin_vendor_service.dart';
import 'package:incanteen/routes/routes_constants.dart';

class AdminManageVendorsPage extends StatefulWidget {
  const AdminManageVendorsPage({super.key});

  @override
  State<AdminManageVendorsPage> createState() => _AdminManageVendorsPageState();
}

class _AdminManageVendorsPageState extends State<AdminManageVendorsPage> {
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
        title: const Text('Manage Vendors'),
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
                hintText: 'Search by vendor name or email...',
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

          // Vendor list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AdminVendorService().getAllVendors(),
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
                          Icons.store_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No vendors found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter vendors based on role and search query
                final vendors = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] as String?;

                  // Only show vendor role users
                  if (role != 'vendor') {
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

                if (vendors.isEmpty) {
                  return Center(
                    child: Text(
                      'No vendors match your search',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: vendors.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ).copyWith(bottom: 80),
                  itemBuilder: (context, index) {
                    final doc = vendors[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final userId = doc.id;
                    final accountName = data['displayName'] as String? ?? 'N/A';

                    // Fetch vendor store info to get storeName
                    return FutureBuilder<DocumentSnapshot>(
                      future: AdminVendorService().getVendorInfo(userId),
                      builder: (context, vendorSnapshot) {
                        String storeName = 'N/A';
                        if (vendorSnapshot.hasData &&
                            vendorSnapshot.data!.exists) {
                          storeName =
                              vendorSnapshot.data!['storeName'] as String? ??
                              'N/A';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              child: const Icon(
                                Icons.store,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              storeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(accountName),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RoutesConstants.adminManageVendorDetailRoute,
                                arguments: {'vendorId': userId},
                              );
                            },
                          ),
                        );
                      },
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
}
