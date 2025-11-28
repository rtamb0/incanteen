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
