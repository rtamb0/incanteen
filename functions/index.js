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

/**
 * Cloud Function to delete a user account (callable by admin only)
 * This function deletes both the Firebase Auth account and Firestore user document
 *
 * Call from client:
 * const deleteUser = firebase.functions().httpsCallable('deleteUser');
 * await deleteUser({ userId: 'user-id-to-delete' });
 */
exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to delete accounts."
    );
  }

  const { userId } = data;

  if (!userId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing userId parameter"
    );
  }

  try {
    // Verify that the caller is an admin
    const callerDoc = await db.collection("users").doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can delete user accounts"
      );
    }

    // Delete Firebase Auth account
    await admin.auth().deleteUser(userId);

    // Delete Firestore user document
    await db.collection("users").doc(userId).delete();

    // Delete vendor document if exists
    try {
      await db.collection("vendors").doc(userId).delete();
    } catch (err) {
      // Vendor doc might not exist, that's okay
      console.log(`No vendor document to delete for ${userId}`);
    }

    // Delete customer document if exists
    try {
      await db.collection("customers").doc(userId).delete();
    } catch (err) {
      // Customer doc might not exist, that's okay
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
    throw new functions.https.HttpsError(
      "internal",
      `Failed to delete user: ${error.message}`
    );
  }
});
