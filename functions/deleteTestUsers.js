/**
 * Script to delete test users
 * Run with: node deleteTestUsers.js
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const testEmails = [
  "customer1@test.com",
  "customer2@test.com",
  "vendor1@test.com",
  "vendor2@test.com",
  "admin1@test.com",
  "admin2@test.com",
];

async function deleteTestUsers() {
  console.log("Deleting test users...\n");

  for (const email of testEmails) {
    try {
      // Get user by email
      const userRecord = await admin.auth().getUserByEmail(email);
      const uid = userRecord.uid;

      // Delete from Auth
      await admin.auth().deleteUser(uid);
      console.log(`✓ Deleted Auth user: ${email}`);

      // Delete from Firestore users collection
      await db.collection("users").doc(uid).delete();
      console.log(`  ✓ Deleted users document`);

      // Delete from customers collection
      const customerDoc = await db.collection("customers").doc(uid).get();
      if (customerDoc.exists) {
        await db.collection("customers").doc(uid).delete();
        console.log(`  ✓ Deleted customers document`);
      }

      // Delete from vendors collection and menus subcollection
      const vendorDoc = await db.collection("vendors").doc(uid).get();
      if (vendorDoc.exists) {
        // Delete all menus
        const menusSnapshot = await db
          .collection("vendors")
          .doc(uid)
          .collection("menus")
          .get();

        const batch = db.batch();
        menusSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();

        if (menusSnapshot.size > 0) {
          console.log(`  ✓ Deleted ${menusSnapshot.size} menu items`);
        }

        await db.collection("vendors").doc(uid).delete();
        console.log(`  ✓ Deleted vendors document`);
      }

      console.log("");
    } catch (error) {
      if (error.code === "auth/user-not-found") {
        console.log(`⚠ User not found: ${email}`);
        console.log("");
      } else {
        console.error(`✗ Error deleting ${email}:`, error.message);
        console.log("");
      }
    }
  }

  console.log("Done!\n");
  process.exit(0);
}

deleteTestUsers().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
