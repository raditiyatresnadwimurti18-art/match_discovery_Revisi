const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function untuk mengirim notifikasi ke semua user
 * saat dokumen baru ditambahkan di koleksi 'lomba'.
 */
exports.sendLombaNotification = functions.firestore
    .document("lomba/{lombaId}")
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();

        if (!data) {
            console.log("Tidak ada data dalam dokumen.");
            return null;
        }

        console.log("Memulai pengiriman notifikasi untuk lomba:", data.judul);

        // Payload Notifikasi
        const message = {
            notification: {
                title: "🏆 Lomba Baru Tersedia!",
                body: `Lomba: ${data.judul} di ${data.lokasi}. Ayo segera daftar!`,
            },
            data: {
                lombaId: context.params.lombaId,
                type: "NEW_LOMBA_ALERT",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            topic: "lomba", // Target semua user yang subscribe ke topik ini
        };

        try {
            // Mengirim pesan via Firebase Cloud Messaging (FCM)
            const response = await admin.messaging().send(message);
            console.log("Notifikasi Berhasil Dikirim:", response);
            return null;
        } catch (error) {
            console.error("Gagal Mengirim Notifikasi:", error);
            return null;
        }
    });
