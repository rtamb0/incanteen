# Admin Features Quick Reference

## Admin Dashboard

After signing in as an admin, you'll see the Admin Dashboard with:

### Statistics Cards

- **Total Users**: Total number of registered users
- **Active Users**: Users with active accounts
- **Customers**: Number of customer accounts
- **Vendors**: Number of vendor accounts

### Management Options

- **Manage Customers**: View and manage all customer accounts
- **Manage Vendors**: View and manage all vendor accounts
- **All Users**: View and manage all users regardless of role

## Managing Users

### Viewing Users

1. From Admin Dashboard, select a management option
2. Use the search bar to find specific users by name or email
3. Pull down to refresh the list
4. Click on any user to view details

### User Details Page

View comprehensive information about a user:

- Display name
- Email address
- Current role
- Account status (Active/Inactive)
- Creation date
- Last update date

### Available Actions

#### Change User Role

1. Click "Change Role" button
2. Select new role (Customer/Vendor/Admin)
3. Confirm the change
4. User's role is updated immediately

#### Deactivate/Activate User

1. Click "Deactivate User" (or "Activate User" if inactive)
2. Account status is toggled
3. Inactive users cannot access the system

#### Delete User

1. Click "Delete User" button
2. Confirm deletion in dialog
3. User's Firestore document is deleted
4. ⚠️ Note: Firebase Auth account remains (requires backend implementation)

## Common Tasks

### Find a specific user

```
Admin Dashboard → All Users → Search by name/email
```

### Convert customer to vendor

```
Admin Dashboard → Manage Customers → Select user → Change Role → Vendor
```

### Temporarily disable an account

```
Admin Dashboard → All Users → Select user → Deactivate User
```

### Create a new admin

```
Admin Dashboard → All Users → Select user → Change Role → Admin
```

### View all vendors

```
Admin Dashboard → Manage Vendors
```

### Remove problematic user

```
Admin Dashboard → All Users → Select user → Delete User → Confirm
```

## Best Practices

### Security

✅ Only grant admin access to trusted users
✅ Regularly review the list of admin users
✅ Use strong passwords for admin accounts
✅ Sign out when finished with admin tasks

### User Management

✅ Communicate with users before changing their roles
✅ Document reasons for deactivating accounts
✅ Keep user data updated and accurate
✅ Regularly review inactive accounts

### Data Privacy

✅ Only access user data when necessary
✅ Don't share user information inappropriately
✅ Follow data protection regulations
✅ Respect user privacy

## Keyboard Shortcuts

Currently, the admin interface doesn't have keyboard shortcuts, but you can:

- Use browser back button to navigate back
- Pull down to refresh lists
- Use search to quickly find users

## Tips & Tricks

### Quick Statistics

Pull down on the Admin Dashboard to refresh statistics in real-time

### Efficient Searching

Search supports partial matches:

- "john" finds "John Doe", "Johnny", etc.
- "gmail" finds all Gmail users

### Filtering by Role

Use the specific management pages instead of searching:

- Manage Customers → only shows customers
- Manage Vendors → only shows vendors
- All Users → shows everyone

### Bulk Viewing

Open multiple user detail pages in different tabs (future enhancement)

## Limitations

Current limitations to be aware of:

❌ Cannot bulk-select and manage multiple users
❌ Cannot export user lists
❌ Firebase Auth accounts not deleted (only Firestore documents)
❌ No activity logs or audit trail
❌ No email notifications to users
❌ Search is client-side (not optimized for large datasets)

See [ADMIN_FEATURE.md](./ADMIN_FEATURE.md) for planned enhancements.

## Troubleshooting

### "Unauthorized" message

- Verify you're signed in as admin
- Check your role in Firebase Console
- Try signing out and back in

### Users not showing up

- Pull down to refresh
- Check your internet connection
- Verify Firestore security rules are deployed

### Cannot perform actions

- Ensure you have admin role
- Check Firebase Console for permission errors
- Verify Firestore rules allow admin operations

### Changes not appearing

- Wait a moment for Firestore to sync
- Pull down to refresh the view
- Navigate away and back to the page

## Support

For technical issues:

1. Check the app console for error messages
2. Review Firebase Console for database errors
3. Verify security rules in `firestore.rules`
4. See detailed documentation in [ADMIN_FEATURE.md](./ADMIN_FEATURE.md)

For feature requests or questions:

- Document the use case
- Describe the desired functionality
- Check if it's in the planned enhancements list
