/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Helper function to verify admin claim
function verifyAdminClaim(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to call this function."
    );
  }

  if (!context.auth.token.admin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User does not have admin privileges."
    );
  }
}

exports.notifyKitchenNewOrder = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();

    // Get the vendor(s) for this order
    const vendorId = order.vendorId;
    const vendorDoc = await db.collection("users").doc(vendorId).get();

    if (!vendorDoc.exists) return null;

    const fcmToken = vendorDoc.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: "New Order Received!",
        body: `Order #${context.params.orderId} has been placed.`,
      },
      data: {
        orderId: context.params.orderId,
        type: "new_order",
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  });

exports.notifyUserOrderReady = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only notify if status changed to 'ready'
    if (before.status === "ready" || after.status !== "ready") return null;

    const userDoc = await db.collection("users").doc(after.userId).get();
    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: "Your Order is Ready!",
        body: `Order #${context.params.orderId} is ready for pickup.`,
      },
      data: {
        orderId: context.params.orderId,
        type: "order_ready",
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  });

// Admin callable function to update user email
exports.adminSetUserEmail = functions.https.onCall(async (data, context) => {
  verifyAdminClaim(context);

  const { uid, email } = data;

  if (!uid || !email) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with uid and email."
    );
  }

  // Validate email format
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(email)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid email format."
    );
  }

  try {
    // Update Firebase Auth email
    await admin.auth().updateUser(uid, { email });

    // Update Firestore user document
    await db.collection("users").doc(uid).update({
      email,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`Admin ${context.auth.uid} updated email for user ${uid} to ${email}`);

    return { success: true, message: "Email updated successfully" };
  } catch (error) {
    logger.error("Error updating user email:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to update email: ${error.message}`
    );
  }
});

// Admin callable function to update user display name
exports.adminSetUserDisplayName = functions.https.onCall(async (data, context) => {
  verifyAdminClaim(context);

  const { uid, displayName } = data;

  if (!uid || !displayName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with uid and displayName."
    );
  }

  // Validate display name
  const trimmedDisplayName = displayName.trim();
  if (trimmedDisplayName.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Display name cannot be empty."
    );
  }
  if (trimmedDisplayName.length > 100) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Display name cannot exceed 100 characters."
    );
  }

  try {
    // Update Firebase Auth display name
    await admin.auth().updateUser(uid, { displayName: trimmedDisplayName });

    // Update Firestore user document
    await db.collection("users").doc(uid).update({
      displayName: trimmedDisplayName,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`Admin ${context.auth.uid} updated displayName for user ${uid} to ${trimmedDisplayName}`);

    return { success: true, message: "Display name updated successfully" };
  } catch (error) {
    logger.error("Error updating user display name:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to update display name: ${error.message}`
    );
  }
});

// Admin callable function to set admin claim for a user
// This function is protected by an allowlist (environment config)
exports.adminSetAdminClaim = functions.https.onCall(async (data, context) => {
  // Check if caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to call this function."
    );
  }

  const { uid, isAdmin } = data;

  if (!uid || typeof isAdmin !== "boolean") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with uid and isAdmin (boolean)."
    );
  }

  // Get allowlist from environment config
  // To set: firebase functions:config:set admin.allowlist="email1@example.com,email2@example.com"
  const allowlistConfig = functions.config().admin?.allowlist || "";
  const allowlist = allowlistConfig.split(",").map((e) => e.trim()).filter((e) => e);

  // If allowlist is empty, this is likely the first-time bootstrap scenario
  // Allow any authenticated user to set the first admin (one-time bootstrap)
  if (allowlist.length === 0) {
    // Check if there are any existing admins
    const usersWithAdmin = await admin.auth().listUsers(1000);
    const existingAdmins = usersWithAdmin.users.filter((u) => u.customClaims?.admin === true);

    if (existingAdmins.length === 0) {
      // No existing admins - allow this as bootstrap
      logger.info(`Bootstrap: ${context.auth.email} is setting first admin for ${uid}`);
    } else {
      // Admins already exist but no allowlist - require admin claim
      if (!context.auth.token.admin) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only existing admins can grant admin privileges. Please configure admin.allowlist for bootstrap."
        );
      }
    }
  } else {
    // Allowlist exists - verify caller is in allowlist OR is already an admin
    const callerEmail = context.auth.token.email;
    const isInAllowlist = allowlist.includes(callerEmail);
    const isCallerAdmin = context.auth.token.admin === true;

    if (!isInAllowlist && !isCallerAdmin) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "User is not authorized to grant admin privileges."
      );
    }
  }

  try {
    // Set or remove admin custom claim
    const customClaims = isAdmin ? { admin: true } : { admin: false };
    await admin.auth().setCustomUserClaims(uid, customClaims);

    logger.info(`Admin claim ${isAdmin ? "granted" : "revoked"} for user ${uid} by ${context.auth.email}`);

    return { 
      success: true, 
      message: `Admin privileges ${isAdmin ? "granted" : "revoked"} successfully` 
    };
  } catch (error) {
    logger.error("Error setting admin claim:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to set admin claim: ${error.message}`
    );
  }
});
