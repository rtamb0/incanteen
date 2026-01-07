/**
 * Cloud Functions for InCanteen
 * Firebase Functions v2 API
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.notifyKitchenNewOrder = onDocumentCreated("orders/{orderId}", async (event) => {
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
});

exports.notifyUserOrderReady = onDocumentUpdated("orders/{orderId}", async (event) => {
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
});

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
    // Verify that the caller is an admin
    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new Error("Only admins can delete user accounts");
    }

    // Delete Firebase Auth account
    await admin.auth().deleteUser(userId);

    // Delete Firestore user document
    await db.collection("users").doc(userId).delete();

    // Delete vendor document if exists
    try {
      await db.collection("vendors").doc(userId).delete();
    } catch (err) {
      console.log(`No vendor document to delete for ${userId}`);
    }

    // Delete customer document if exists
    try {
      await db.collection("customers").doc(userId).delete();
    } catch (err) {
      console.log(`No customer document to delete for ${userId}`);
    }

    // Delete all orders for this user
    const ordersSnapshot = await db
      .collection("orders")
      .where("userId", "==", userId)
      .get();

    const batch = db.batch();
    ordersSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    return {
      success: true,
      message: `User ${userId} and all associated data have been deleted`,
    };
  } catch (error) {
    console.error("Error deleting user:", error);
    throw new Error(`Failed to delete user: ${error.message}`);
  }
});
