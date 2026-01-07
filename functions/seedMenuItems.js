/**
 * Script to create sample menu items for vendors
 * Run with: node seedMenuItems.js
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const vendorMenus = {
  // Get actual vendor IDs from your test users
  // vendor1 and vendor2 should be replaced with actual UIDs
  vendor1: [
    {
      name: "Nasi Goreng Spesial",
      description: "Nasi goreng dengan telur, sayuran, dan daging ayam",
      price: 25000,
      category: "Main Course",
    },
    {
      name: "Mie Goreng",
      description: "Mie kuning goreng dengan bumbu khas",
      price: 20000,
      category: "Main Course",
    },
    {
      name: "Lumpia Goreng",
      description: "Lumpia isi daging cincang dan sayuran",
      price: 15000,
      category: "Appetizer",
    },
    {
      name: "Es Teh Manis",
      description: "Minuman penyegar teh dengan gula",
      price: 5000,
      category: "Beverage",
    },
    {
      name: "Ayam Goreng",
      description: "Ayam goreng renyah dengan sambal",
      price: 30000,
      category: "Main Course",
    },
  ],
  vendor2: [
    {
      name: "Burger Beef",
      description: "Burger premium dengan daging sapi pilihan",
      price: 35000,
      category: "Main Course",
    },
    {
      name: "Chicken Sandwich",
      description: "Sandwich ayam dengan saus spesial",
      price: 28000,
      category: "Main Course",
    },
    {
      name: "French Fries",
      description: "Kentang goreng renyah dan gurih",
      price: 15000,
      category: "Side",
    },
    {
      name: "Soft Drink",
      description: "Minuman dingin pilihan (Sprite, Coca-Cola, Fanta)",
      price: 8000,
      category: "Beverage",
    },
    {
      name: "Ice Cream Sundae",
      description: "Es krim dengan topping cokelat dan kacang",
      price: 20000,
      category: "Dessert",
    },
  ],
};

async function seedMenuItems() {
  console.log("Seeding menu items...\n");

  // First, get all vendors to find their actual IDs
  const usersSnapshot = await db
    .collection("users")
    .where("role", "==", "vendor")
    .limit(2)
    .get();

  if (usersSnapshot.empty) {
    console.log("No vendors found. Please run seedTestUsers.js first.\n");
    process.exit(1);
  }

  const vendors = [];
  usersSnapshot.forEach((doc) => {
    vendors.push({
      id: doc.id,
      displayName: doc.data().displayName,
    });
  });

  console.log(`Found ${vendors.length} vendors\n`);

  // Add menus for each vendor
  for (let i = 0; i < vendors.length; i++) {
    const vendor = vendors[i];
    const menus = vendorMenus[`vendor${i + 1}`] || [];

    console.log(`Adding menus to ${vendor.displayName} (${vendor.id})...`);

    for (const menu of menus) {
      try {
        await db.collection("vendors").doc(vendor.id).collection("menus").add({
          name: menu.name,
          description: menu.description,
          price: menu.price,
          category: menu.category,
          isAvailable: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`  ✓ Added: ${menu.name} (Rp ${menu.price})`);
      } catch (error) {
        console.error(`  ✗ Error adding ${menu.name}:`, error.message);
      }
    }

    console.log("");
  }

  console.log("Done! Menu items have been added to all vendors.\n");
  process.exit(0);
}

seedMenuItems().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
