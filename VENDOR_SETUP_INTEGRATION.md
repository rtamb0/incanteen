# Vendor Setup Integration Summary

## Overview

Completed the refactoring of vendor onboarding workflow, moving vendor setup fields from signup page to a dedicated first-login page. This provides a cleaner signup experience and defers vendor store information collection until after account creation.

## Changes Made

### 1. **Signup Page Simplified** (`lib/pages/auth/signup_page.dart`)

- ✅ Removed all vendor-related fields:
  - Removed vendor name TextFormField
  - Removed vendor address TextFormField
  - Removed vendor field validators
- ✅ Kept role selection dropdown (customer/vendor)
- ✅ Signup now only collects: email, password, display name, and role selection

### 2. **Created VendorSetupPage** (`lib/pages/auth/vendor_setup_page.dart`)

- ✅ New StatefulWidget for vendor onboarding on first login
- ✅ Collects store information:
  - Store name (validates: non-empty, minimum 3 characters)
  - Store location/address (validates: non-empty, minimum 5 characters)
- ✅ On submission:
  - Creates `/vendors/{userId}` document with name and location
  - Sets `vendorSetupComplete: true` on user document
  - Triggers `AuthService.roleRefreshNotifier` to refresh auth state
  - Navigates to vendor dashboard

### 3. **Updated Routes** (`lib/routes/routes_constants.dart` & `lib/routes/router.dart`)

- ✅ Added `vendorSetupRoute = "/vendor-setup"` constant
- ✅ Added VendorSetupPage import to router.dart
- ✅ Added route handler case for `/vendor-setup`:
  ```dart
  case RoutesConstants.vendorSetupRoute:
    return MaterialPageRoute(builder: (_) => const VendorSetupPage());
  ```

### 4. **Updated Main Auth Flow** (`lib/main.dart`)

- ✅ Added imports for VendorSetupPage and Firestore
- ✅ Modified vendor role handling in AuthWrapper:
  - When `role == 'vendor'`, checks `vendorSetupComplete` flag
  - If `vendorSetupComplete == false`: shows VendorSetupPage
  - If `vendorSetupComplete == true`: shows VendorDashboard

## Complete Vendor Signup Flow

### New User Registration (Vendor)

1. User navigates to signup page
2. Enters: email, password, display name
3. Selects **vendor** as role
4. Account created in Firebase Auth
5. User document created in Firestore with:
   - `email`
   - `displayName`
   - `role: "vendor"`
   - `createdAt`
   - `vendorSetupComplete: false` (default)
6. AuthWrapper detects new vendor with incomplete setup
7. **VendorSetupPage displayed** (first-time prompt)
8. Vendor enters store name and location
9. `/vendors/{userId}` document created
10. `vendorSetupComplete` flag set to `true`
11. AuthWrapper refreshes and routes to **VendorDashboard**

### Returning Vendor Login

1. User logs in with vendor credentials
2. AuthWrapper checks role: `vendor`
3. Checks `vendorSetupComplete` flag: `true`
4. Routes directly to **VendorDashboard**

### Incomplete Vendor Setup

- If vendor hasn't completed setup (flag is false or missing):
  - Always shown VendorSetupPage on login
  - Can retry setup, can also sign out if needed

## Database Schema Updated

### Users Collection

```
users/{userId}
├── email: string
├── displayName: string
├── role: string ("vendor" | "customer" | "admin")
├── createdAt: timestamp
├── updatedAt: timestamp
├── vendorSetupComplete: boolean (false for new vendors)
└── [other fields...]
```

### Vendors Collection

```
vendors/{userId}
├── name: string (store name)
├── location: string (store address)
├── createdAt: timestamp
└── [menu items, etc...]
```

## Files Modified

1. `lib/pages/auth/signup_page.dart` - Removed vendor fields
2. `lib/routes/routes_constants.dart` - Added vendorSetupRoute constant
3. `lib/routes/router.dart` - Added VendorSetupPage import and route handler
4. `lib/main.dart` - Updated vendor role logic with setup check

## Files Created

1. `lib/pages/auth/vendor_setup_page.dart` - New vendor onboarding page

## Testing Checklist

- [ ] Signup with vendor role (should show vendor setup on next login)
- [ ] Complete vendor setup (should show store name/location form)
- [ ] Verify vendor store document created in Firestore
- [ ] Verify vendorSetupComplete flag set to true
- [ ] Login as returning vendor (should skip setup and go to dashboard)
- [ ] Login as incomplete vendor (should show setup page again)
- [ ] Signup with customer role (should go directly to customer home)
- [ ] Signup with admin role (should go directly to admin dashboard)
- [ ] Test form validation (empty fields, short inputs)
- [ ] Test error handling (network failures, Firestore errors)

## Role-Based Routing Summary

| Role       | Setup Status | Route                 |
| ---------- | ------------ | --------------------- |
| admin      | N/A          | AdminDashboard        |
| vendor     | incomplete   | VendorSetupPage       |
| vendor     | complete     | VendorDashboard       |
| customer   | N/A          | CustomerHome          |
| (new user) | N/A          | FinalisingAccountPage |

## Notes

- The `vendorSetupComplete` flag defaults to false for new vendor accounts
- VendorSetupPage validates store name (≥3 chars) and location (≥5 chars)
- Setup page cannot be skipped; vendor must complete before accessing dashboard
- AuthService.roleRefreshNotifier is triggered to refresh routing after setup
- Signup page remains simple and focused (no vendor-specific fields shown)
