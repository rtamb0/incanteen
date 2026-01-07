/**
 * Cloud Functions for InCanteen
 * Firebase Functions v2 API
 */

const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.notifyKitchenNewOrder = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    const order = event.data.data();
    const orderId = event.params.orderId;

    // Get the vendor(s) for this order
    const vendorId = order.vendorId;
    const vendorDoc = await db.collection("users").doc(vendorId).get();

    if (!vendorDoc.exists) return null;

    const fcmToken = vendorDoc.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: "New Order Received!",
        body: `Order #${orderId} has been placed.`,
      },
      data: {
        orderId: orderId,
        type: "new_order",
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  }
);

exports.notifyUserOrderReady = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const orderId = event.params.orderId;

    // Only notify if status changed to 'ready'
    if (before.status === "ready" || after.status !== "ready") return null;

    const userDoc = await db.collection("users").doc(after.userId).get();
    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: "Your Order is Ready!",
        body: `Order #${orderId} is ready for pickup.`,
      },
      data: {
        orderId: orderId,
        type: "order_ready",
      },
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  }
);

/**
 * Cloud Function to delete a user account (callable by admin only)
 * This function deletes both the Firebase Auth account and Firestore user document
 */
exports.deleteUser = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new Error("User must be authenticated to delete accounts.");
  }

  const { userId } = request.data;

  if (!userId) {
    throw new Error("Missing userId parameter");
  }

  try {
    // Verify that the caller is admin or superadmin
    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    const callerRole = callerDoc.exists ? callerDoc.data().role : null;
    if (callerRole !== "admin" && callerRole !== "superadmin") {
      throw new Error("Only admins or superadmins can delete user accounts");
    }

    // Get target user info for audit log
    const targetUserDoc = await db.collection("users").doc(userId).get();
    const targetUserRole = targetUserDoc.exists
      ? targetUserDoc.data().role
      : null;
    const targetUserEmail = targetUserDoc.exists
      ? targetUserDoc.data().email
      : null;

    // Delete Firebase Auth account
    await admin.auth().deleteUser(userId);

    // Delete Firestore user document
    await db.collection("users").doc(userId).delete();

    // Delete vendor document and menus if exists
    try {
      const menusSnapshot = await db
        .collection("vendors")
        .doc(userId)
        .collection("menus")
        .get();

      const menuBatch = db.batch();
      menusSnapshot.forEach((doc) => {
        menuBatch.delete(doc.ref);
      });
      await menuBatch.commit();

      await db.collection("vendors").doc(userId).delete();
      console.log(`Deleted vendor ${userId} and ${menusSnapshot.size} menus`);
    } catch (err) {
      console.log(`No vendor document to delete for ${userId}`);
    }

    // Delete customer document if exists
    try {
      await db.collection("customers").doc(userId).delete();
    } catch (err) {
      console.log(`No customer document to delete for ${userId}`);
    }

    // Delete all orders for this user (both as customer and vendor)
    const ordersSnapshot = await db
      .collection("orders")
      .where("userId", "==", userId)
      .get();

    const batch = db.batch();
    ordersSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // Delete all orders from vendors (if vendor is being deleted)
    const vendorOrdersSnapshot = await db
      .collection("orders")
      .where("vendorId", "==", userId)
      .get();

    const vendorBatch = db.batch();
    vendorOrdersSnapshot.forEach((doc) => {
      vendorBatch.delete(doc.ref);
    });
    await vendorBatch.commit();

    // Create audit log entry
    await db.collection("auditLogs").add({
      action: "deleteUser",
      adminUid: request.auth.uid,
      targetUserId: userId,
      targetUserRole: targetUserRole,
      targetUserEmail: targetUserEmail,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: `User ${userId} and all associated data have been deleted`,
    };
  } catch (error) {
    console.error("Error deleting user:", error);
    throw new Error(`Failed to delete user: ${error.message}`);
  }
});
/**
 * Cloud Function to update user role (callable by admin only)
 * Logs the role change to auditLogs
 */
exports.updateUserRole = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new Error("User must be authenticated to update roles.");
  }

  const { userId, newRole } = request.data;

  if (!userId || !newRole) {
    throw new Error("Missing userId or newRole parameter");
  }

  try {
    // Verify that the caller is admin or superadmin
    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    const callerRole = callerDoc.exists ? callerDoc.data().role : null;
    if (callerRole !== "admin" && callerRole !== "superadmin") {
      throw new Error("Only admins or superadmins can update user roles");
    }

    // Get target user info
    const targetUserDoc = await db.collection("users").doc(userId).get();
    if (!targetUserDoc.exists) {
      throw new Error("Target user not found");
    }

    const targetUserData = targetUserDoc.data();
    const targetUserRole = targetUserData.role;
    const targetUserEmail = targetUserData.email;

    // Admin cannot modify admin or superadmin accounts
    const isSuperAdmin = callerRole === "superadmin";
    if (
      !isSuperAdmin &&
      (targetUserRole === "admin" || targetUserRole === "superadmin")
    ) {
      throw new Error(
        "You do not have permission to modify admin or superadmin accounts"
      );
    }

    // No one can assign superadmin role
    if (newRole === "superadmin") {
      throw new Error("Superadmin role cannot be assigned");
    }

    // Admin cannot create admin accounts
    if (!isSuperAdmin && newRole === "admin") {
      throw new Error("Only superadmins can create admin accounts");
    }

    // Update user role
    await db.collection("users").doc(userId).update({
      role: newRole,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create audit log entry
    await db.collection("auditLogs").add({
      action: "updateUserRole",
      adminUid: request.auth.uid,
      targetUserId: userId,
      targetUserRole: targetUserRole,
      targetUserEmail: targetUserEmail,
      newRole: newRole,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: `User role updated from ${targetUserRole} to ${newRole}`,
    };
  } catch (error) {
    console.error("Error updating user role:", error);
    throw new Error(`Failed to update user role: ${error.message}`);
  }
});
