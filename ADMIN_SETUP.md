# Admin Setup Guide

This document explains how to set up and manage admin users in the InCanteen application.

## Overview

The InCanteen application uses Firebase Authentication custom claims to manage admin privileges. Admins have elevated permissions to:
- View all customers and vendors
- Edit user profile information (display name and email)
- Grant or revoke admin privileges to other users

## Security Implementation

### Firestore Security Rules
The application implements role-based access control (RBAC) through Firestore security rules:
- Authenticated users can read/update their own user document (non-privileged fields only)
- Users cannot modify their own `role` field or admin-related fields
- Only users with `admin` custom claim can:
  - Read all user documents
  - Update any user document
  - Manage vendors collection
  - Access all orders

### Cloud Functions
Admin operations are secured through Cloud Functions that verify the caller has admin privileges:
- `adminSetUserEmail` - Updates user email in Firebase Auth and Firestore
- `adminSetUserDisplayName` - Updates user display name in Firebase Auth and Firestore
- `adminSetAdminClaim` - Grants or revokes admin custom claims

## Setting Up the First Admin

There are two methods to set up the first admin user:

### Method 1: Bootstrap Mode (First-Time Setup)

When no admin users exist and no allowlist is configured, the system allows one-time bootstrap:

1. **Create a regular user account** through the app signup flow (as customer or vendor)

2. **Deploy the Cloud Functions** (if not already deployed):
   ```bash
   cd functions
   firebase deploy --only functions
   ```

3. **Use the admin claim function** from the Flutter app or Firebase Console:
   
   From the app, once logged in, you can call the admin service (you'll need to add a temporary UI or use Flutter DevTools):
   ```dart
   await AdminService().setAdminClaim('YOUR_USER_UID', true);
   ```
   
   Or use Firebase CLI to call the function:
   ```bash
   firebase functions:shell
   > adminSetAdminClaim({uid: 'YOUR_USER_UID', isAdmin: true})
   ```

4. **Sign out and sign back in** for the custom claim to take effect

### Method 2: Using Allowlist (Recommended for Production)

Set up an allowlist of email addresses that can grant admin privileges:

1. **Configure the allowlist** using Firebase Functions config:
   ```bash
   firebase functions:config:set admin.allowlist="admin1@example.com,admin2@example.com"
   ```

2. **Deploy the functions** with the new configuration:
   ```bash
   cd functions
   firebase deploy --only functions
   ```

3. **Users in the allowlist** can now call `adminSetAdminClaim` to grant admin privileges:
   - Log in with an email from the allowlist
   - Call the admin service to grant admin privileges to any user UID
   - Once admin claim is set, sign out and sign back in

### Method 3: Manual Setup via Firebase Admin SDK

For quick setup during development:

1. **Create a one-time script** or use Firebase Functions shell:
   ```javascript
   const admin = require('firebase-admin');
   admin.initializeApp();
   
   // Set admin claim for a specific user
   admin.auth().setCustomUserClaims('USER_UID_HERE', { admin: true })
     .then(() => {
       console.log('Admin claim set successfully');
     })
     .catch(error => {
       console.error('Error setting admin claim:', error);
     });
   ```

2. Run this in a Node.js environment with Firebase Admin SDK initialized

3. The user must **sign out and sign back in** for the claim to take effect

## Managing Admin Users

### Granting Admin Privileges

Once you have at least one admin user:

1. Log in as an admin
2. Navigate to the Admin Dashboard
3. (Future enhancement: Add UI to grant admin privileges directly from the dashboard)
   
   For now, use the AdminService programmatically:
   ```dart
   await AdminService().setAdminClaim(targetUserId, true);
   ```

### Revoking Admin Privileges

To revoke admin privileges:
```dart
await AdminService().setAdminClaim(targetUserId, false);
```

The user will lose admin access after signing out and signing back in.

## Admin Dashboard Features

The Admin Dashboard provides:

### Customer Management
- View all users with `role: customer`
- See user details (display name, email, role)
- Edit user display name and email

### Vendor Management
- View all users with `role: vendor`
- See user details (display name, email, role)
- Check if vendor has a linked `vendors/{uid}` document
- Edit vendor user information

### Editing User Information

When editing users:
- **Display Name**: Updated in both Firebase Auth and Firestore via Cloud Function
- **Email**: Updated in both Firebase Auth and Firestore via Cloud Function (requires admin privileges)

## Important Notes

1. **Custom Claims Refresh**: Custom claims are included in the user's ID token. After setting/revoking admin claims, users must sign out and sign back in for changes to take effect.

2. **Security Best Practices**:
   - Keep the allowlist minimal and secure
   - Regularly audit admin users
   - Use the allowlist method in production environments
   - Revoke admin access when no longer needed

3. **Cloud Function Requirements**:
   - All admin callable functions verify the caller has admin custom claim
   - The `adminSetAdminClaim` function has special bootstrap logic for first-time setup
   - Functions use Firebase Admin SDK for privileged operations

## Troubleshooting

### "Permission denied" when calling admin functions
- Ensure you have the admin custom claim set
- Sign out and sign back in to refresh your ID token
- Check that Cloud Functions are deployed and updated

### Admin claim not taking effect
- Sign out completely and sign back in
- Clear app cache if needed
- Verify the claim was set using Firebase Console > Authentication > Users

### Bootstrap mode not working
- Ensure no admin users exist in the system
- Verify no allowlist is configured
- Check Cloud Functions logs for detailed error messages

## Additional Resources

- [Firebase Custom Claims Documentation](https://firebase.google.com/docs/auth/admin/custom-claims)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
