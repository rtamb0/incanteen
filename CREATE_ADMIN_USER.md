# Creating the First Admin User

Since admin users cannot be created through the signup UI (for security reasons), you need to manually promote an existing user to admin role.

## Method 1: Using Firebase Console (Recommended)

1. **Create a regular user account**:

   - Open your app
   - Sign up with a new account (choose either Customer or Vendor role)
   - Note the email address used

2. **Open Firebase Console**:

   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project: `incanteen`

3. **Navigate to Firestore Database**:

   - Click on "Firestore Database" in the left sidebar
   - Click on the `users` collection

4. **Find your user**:

   - Look for the document with your email address
   - Click on the document to open it

5. **Update the role field**:

   - Find the `role` field
   - Change the value from `"customer"` or `"vendor"` to `"admin"`
   - Click Save

6. **Sign out and sign back in**:
   - In your app, sign out
   - Sign back in with the same credentials
   - You should now see the Admin Dashboard

## Method 2: Using Firebase CLI (Advanced)

If you prefer using the Firebase CLI:

```bash
# Install Firebase Admin SDK (requires Node.js)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Create a script file: promote-admin.js
```

Create `promote-admin.js`:

```javascript
const admin = require("firebase-admin");
const serviceAccount = require("./path/to/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function promoteToAdmin(email) {
  try {
    // Find user by email
    const usersRef = db.collection("users");
    const snapshot = await usersRef.where("email", "==", email).get();

    if (snapshot.empty) {
      console.log("No user found with email:", email);
      return;
    }

    // Update first matching user
    const doc = snapshot.docs[0];
    await doc.ref.update({
      role: "admin",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("Successfully promoted user to admin:", email);
  } catch (error) {
    console.error("Error promoting user:", error);
  }
}

// Replace with the email you want to promote
promoteToAdmin("your-email@example.com");
```

Run the script:

```bash
node promote-admin.js
```

## Method 3: Firestore REST API

You can also use the Firestore REST API with curl:

```bash
# Set your variables
PROJECT_ID="your-project-id"
USER_DOC_ID="user-document-id"

curl -X PATCH \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/users/$USER_DOC_ID?updateMask.fieldPaths=role" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "role": {
        "stringValue": "admin"
      }
    }
  }'
```

## Verifying Admin Access

After promoting a user to admin:

1. Sign in to the app with the promoted account
2. You should be automatically redirected to the Admin Dashboard
3. Verify you can see:
   - User statistics
   - "Manage Customers" option
   - "Manage Vendors" option
   - "All Users" option

## Creating Additional Admins

Once you have one admin user, you can create additional admins through the app:

1. Sign in as an existing admin
2. Navigate to "All Users"
3. Select the user you want to promote
4. Click "Change Role"
5. Select "Admin"
6. Confirm the change

## Security Notes

⚠️ **Important Security Considerations**:

- Admin users have unrestricted access to all user data
- Keep admin credentials secure
- Use strong passwords for admin accounts
- Consider enabling 2FA for admin accounts (future feature)
- Regularly audit admin user list
- Remove admin privileges when no longer needed

## Troubleshooting

### Issue: Changes not reflecting after updating role

**Solution**:

- Sign out completely from the app
- Close and reopen the app
- Sign back in

### Issue: "Unauthorized" error in admin pages

**Solution**:

- Verify the role field is exactly `"admin"` (lowercase)
- Check Firestore security rules are properly deployed:
  ```bash
  firebase deploy --only firestore:rules
  ```

### Issue: Cannot find user in Firestore

**Solution**:

- Ensure the user has completed signup
- Check the `users` collection exists
- Verify the user document was created during signup

## Next Steps

After creating your first admin:

1. Test all admin features
2. Create user management policies
3. Document which users should have admin access
4. Set up regular security audits
5. Consider implementing activity logging

For more information, see [ADMIN_FEATURE.md](./ADMIN_FEATURE.md)
