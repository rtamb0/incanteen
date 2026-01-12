/**
 * Script to create test users for development
 * Run with: node seedTestUsers.js
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const testUsers = [
  // Customers
  {
    email: "customer1@test.com",
    password: "Test123!",
    displayName: "Customer One",
    role: "customer",
    phoneNumber: "081234567891",
  },
  {
    email: "customer2@test.com",
    password: "Test123!",
    displayName: "Customer Two",
    role: "customer",
    phoneNumber: "081234567892",
  },
  // Vendors
  {
    email: "vendor1@test.com",
    password: "Test123!",
    displayName: "Vendor One",
    role: "vendor",
    phoneNumber: "081234567893",
    vendorData: {
      storeName: "Warung Makan Satu",
      storeLocation: "Kantin B1",
      storeDescription:
        "Menyajikan makanan Indonesia dengan cita rasa autentik",
    },
  },
  {
    email: "vendor2@test.com",
    password: "Test123!",
    displayName: "Vendor Two",
    role: "vendor",
    phoneNumber: "081234567894",
    vendorData: {
      storeName: "Warung Makan Dua",
      storeLocation: "Kantin B2",
      storeDescription: "Spesialis makanan cepat saji dan minuman",
    },
  },
  // Admins
  {
    email: "admin1@test.com",
    password: "Test123!",
    displayName: "Admin One",
    role: "admin",
    phoneNumber: "081234567895",
  },
  {
    email: "admin2@test.com",
    password: "Test123!",
    displayName: "Admin Two",
    role: "admin",
    phoneNumber: "081234567896",
  },
];

async function createTestUsers() {
  console.log("Creating test users...\n");

  for (const userData of testUsers) {
    try {
      // Create Firebase Auth user
      const userRecord = await admin.auth().createUser({
        email: userData.email,
        password: userData.password,
        displayName: userData.displayName,
        emailVerified: true,
      });

      console.log(`✓ Created Auth user: ${userData.email} (${userRecord.uid})`);

      // Create Firestore user document
      await db
        .collection("users")
        .doc(userRecord.uid)
        .set({
          uid: userRecord.uid,
          email: userData.email,
          displayName: userData.displayName,
          role: userData.role,
          phoneNumber: userData.phoneNumber || "",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`  ✓ Created Firestore user document`);

      // Create role-specific documents
      if (userData.role === "customer") {
        await db.collection("customers").doc(userRecord.uid).set({
          uid: userRecord.uid,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`  ✓ Created customer document`);
      } else if (userData.role === "vendor" && userData.vendorData) {
        await db.collection("vendors").doc(userRecord.uid).set({
          uid: userRecord.uid,
          storeName: userData.vendorData.storeName,
          storeLocation: userData.vendorData.storeLocation,
          storeDescription: userData.vendorData.storeDescription,
          storeImageUrl: "",
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(
          `  ✓ Created vendor document: ${userData.vendorData.storeName}`
        );
      }

      console.log("");
    } catch (error) {
      if (error.code === "auth/email-already-exists") {
        console.log(`⚠ User already exists: ${userData.email}`);
        console.log("");
      } else {
        console.error(`✗ Error creating ${userData.email}:`, error.message);
        console.log("");
      }
    }
  }

  console.log("Done!\n");
  console.log("Test credentials:");
  console.log("================");
  testUsers.forEach((user) => {
    console.log(`${user.role.toUpperCase()}: ${user.email} / ${user.password}`);
  });

  process.exit(0);
}

createTestUsers().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
