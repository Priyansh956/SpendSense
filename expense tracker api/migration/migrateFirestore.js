const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
require("dotenv").config();

// Connect to MongoDB
require("../config/db");

// Service account
const serviceAccount = require("../serviceAccountKey.json");

// Initialize Firebase
initializeApp({
    credential: cert(serviceAccount),
});

// Firestore instance
const firestore = getFirestore();

async function migrate() {
    try {
        console.log("Connected to Firebase!");

        // Replace "transactions" with your collection name
        const snapshot = await firestore.collection("users").get();

        console.log(`Found ${snapshot.size} users\n`);

        snapshot.forEach((doc) => {
            console.log("Document ID:", doc.id);
            console.log(doc.data());
            console.log("--------------------------------");
        });

        process.exit(0);

    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

migrate();