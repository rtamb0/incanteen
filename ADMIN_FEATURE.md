# Admin Role & User Management

This document describes the admin role implementation and user management system for InCanteen.

## Overview

The admin role provides privileged access to view and manage all customers and vendors registered in the system. Admin users have a dedicated dashboard with comprehensive user management capabilities.

## Features

### 1. Admin Dashboard

- **Location**: `lib/pages/admin/admin_dashboard.dart`
- **Route**: `/admin-dashboard`
- Displays user statistics (total users, active users, customers, vendors, admins)
- Provides quick access to user management pages
- Role-based navigation from main AuthWrapper

### 2. User Management

- **Location**: `lib/pages/admin/admin_manage_users_page.dart`
- **Route**: `/admin-manage-users`
- View all users or filter by role (customer/vendor)
- Search users by name or email
- Real-time updates via Firestore streams
- Navigate to individual user details

### 3. User Detail & Actions

- **Location**: `lib/pages/admin/admin_user_detail_page.dart`
- **Route**: `/admin-user-detail`
- View complete user information
- Change user roles (customer/vendor/admin)
- Activate/deactivate user accounts
- Delete user accounts

### 4. Admin Service

- **Location**: `lib/services/admin/admin_service.dart`
- Centralized service for all admin operations
- User CRUD operations
- User statistics calculation
- Role validation and authorization checks

## User Roles

The system supports three user roles:

- **customer**: Regular users who can browse and place orders
- **vendor**: Users who can manage their store and menus
- **admin**: Privileged users with full system access

## Security & RBAC

### Firestore Security Rules

The Firestore security rules (`firestore.rules`) implement Role-Based Access Control (RBAC):

```javascript
// Admins can read all user documents
allow read: if isAdmin();

// Admins can update any user (including role changes)
allow update: if isAdmin();

// Admins can delete users
allow delete: if isAdmin();
```

### Admin Guard

- **Location**: `lib/helper/admin_guard.dart`
- Widget wrapper that checks admin privileges
- Can be used to protect admin-only pages
- Shows unauthorized message for non-admin users

### Application-Level Checks

All admin operations in `AdminService` verify admin privileges:

```dart
Future<void> updateUserRole(String userId, String newRole) async {
  if (!await isAdmin()) {
    throw Exception('Unauthorized: Admin access required');
  }
  // ... operation code
}
```

## Creating Admin Users

### Method 1: Manual Database Update (Recommended for first admin)

1. Create a user account through normal signup
2. Open Firebase Console
3. Navigate to Firestore Database
4. Find the user document in `users` collection
5. Update the `role` field to `'admin'`

### Method 2: Through Existing Admin

Once you have at least one admin user:

1. Sign in as admin
2. Navigate to user management
3. Select any user
4. Change their role to "Admin"

## Routes

| Route                 | Constant                | Page            | Access     |
| --------------------- | ----------------------- | --------------- | ---------- |
| `/admin-dashboard`    | `adminDashboardRoute`   | Admin Dashboard | Admin only |
| `/admin-manage-users` | `adminManageUsersRoute` | User Management | Admin only |
| `/admin-user-detail`  | `adminUserDetailRoute`  | User Details    | Admin only |

## Authentication Flow

```
User Login
    ↓
AuthWrapper (main.dart)
    ↓
getUserRole()
    ↓
role == 'admin' → AdminDashboard
role == 'vendor' → VendorDashboard
role == 'customer' → CustomerHome
```

## API Methods

### AdminService Methods

```dart
// Check if current user is admin
Future<bool> isAdmin()

// Get all users with optional role filter
Stream<QuerySnapshot> getAllUsers({String? roleFilter})

// Get user by ID
Future<DocumentSnapshot> getUserById(String userId)

// Update user role
Future<void> updateUserRole(String userId, String newRole)

// Delete user
Future<void> deleteUser(String userId)

// Toggle user active status
Future<void> toggleUserStatus(String userId, bool isActive)

// Get user statistics
Future<Map<String, int>> getUserStatistics()

// Search users
Stream<QuerySnapshot> searchUsers(String query)
```

## User Data Model

```dart
{
  'displayName': String,
  'email': String,
  'role': String,  // 'customer', 'vendor', or 'admin'
  'isActive': bool,  // true by default
  'createdAt': Timestamp,
  'updatedAt': Timestamp?,
  'fcmToken': String?,
  'fcmUpdatedAt': Timestamp?
}
```

## Future Enhancements

### Planned Features

1. **Bulk Operations**: Select and manage multiple users at once
2. **User Activity Logs**: Track admin actions and user activities
3. **Advanced Analytics**: Detailed charts and reports
4. **Email Notifications**: Notify users of role changes or account status
5. **Export Data**: Export user lists to CSV/Excel
6. **User Permissions**: Fine-grained permission system beyond basic roles

### Technical Improvements

1. **Full-text Search**: Integration with Algolia or ElasticSearch
2. **Firebase Admin SDK**: Complete user deletion (Auth + Firestore)
3. **Audit Trail**: Log all administrative actions
4. **Two-Factor Authentication**: Enhanced security for admin accounts

## Testing

To test admin functionality:

1. Create a test user and manually set role to 'admin'
2. Sign in with the admin account
3. Verify dashboard displays correct statistics
4. Test user management:
   - View all users
   - Filter by role
   - Search functionality
   - View user details
   - Change user role
   - Toggle user status
   - Delete user

## Troubleshooting

### "Unauthorized: Admin access required"

- Verify the user's role field is set to 'admin' in Firestore
- Check Firestore security rules are properly deployed
- Ensure the user is properly authenticated

### Users not appearing in list

- Check Firestore indexes are created
- Verify security rules allow admin read access
- Check for network connectivity issues

### Cannot delete users

- Note: Current implementation only deletes Firestore document
- Firebase Auth account deletion requires Firebase Admin SDK
- Consider implementing as a Cloud Function

## Support

For issues or questions:

1. Check Firebase Console for error logs
2. Review Firestore security rules
3. Verify user permissions in database
4. Check application logs for detailed error messages
