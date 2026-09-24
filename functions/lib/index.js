"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onTripStatusChanged = exports.onTripCreated = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
// ─── Helper: send FCM to a single token ───────────────────────────────────────
async function sendNotification(token, title, body, data) {
    try {
        await messaging.send({
            token,
            notification: { title, body },
            data: data !== null && data !== void 0 ? data : {},
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                    channelId: "yeride_trips",
                },
            },
        });
    }
    catch (err) {
        console.error("FCM send error:", err);
    }
}
// ─── Helper: get FCM token from a collection doc ──────────────────────────────
async function getToken(collection, uid) {
    var _a, _b;
    const doc = await db.collection(collection).doc(uid).get();
    return (_b = (_a = doc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken) !== null && _b !== void 0 ? _b : null;
}
// ─────────────────────────────────────────────────────────────────────────────
// FUNCTION 1: New trip created → notify the assigned rider
// ─────────────────────────────────────────────────────────────────────────────
exports.onTripCreated = (0, firestore_1.onDocumentCreated)("trips/{tripId}", async (event) => {
    var _a, _b, _c, _d;
    const trip = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!trip)
        return;
    const assignedRiderId = trip.assignedRiderId;
    if (!assignedRiderId)
        return;
    const token = await getToken("riders", assignedRiderId);
    if (!token) {
        console.log(`No FCM token for rider ${assignedRiderId}`);
        return;
    }
    const pickup = (_b = trip.pickupAddress) !== null && _b !== void 0 ? _b : "Unknown";
    const destination = (_c = trip.destinationAddress) !== null && _c !== void 0 ? _c : "Unknown";
    const fare = ((_d = trip.fare) !== null && _d !== void 0 ? _d : 0).toFixed(2);
    await sendNotification(token, "🏍 New Ride Request!", `${pickup} → ${destination} · GH₵ ${fare}`, {
        type: "new_trip",
        tripId: event.params.tripId,
        pickup,
        destination,
        fare,
    });
    console.log(`Notified rider ${assignedRiderId} of new trip ${event.params.tripId}`);
});
// ─────────────────────────────────────────────────────────────────────────────
// FUNCTION 2: Trip status updated → notify relevant party
// ─────────────────────────────────────────────────────────────────────────────
exports.onTripStatusChanged = (0, firestore_1.onDocumentUpdated)("trips/{tripId}", async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const oldStatus = before.status;
    const newStatus = after.status;
    // Only act when status actually changed
    if (oldStatus === newStatus)
        return;
    const tripId = event.params.tripId;
    const passengerId = after.passengerId;
    const riderId = after.riderId;
    const pickup = (_c = after.pickupAddress) !== null && _c !== void 0 ? _c : "Unknown";
    const destination = (_d = after.destinationAddress) !== null && _d !== void 0 ? _d : "Unknown";
    const riderName = (_e = after.riderName) !== null && _e !== void 0 ? _e : "Your rider";
    switch (newStatus) {
        // Rider accepted → notify passenger
        case "accepted": {
            if (!passengerId)
                break;
            const token = await getToken("users", passengerId);
            if (!token)
                break;
            await sendNotification(token, "✅ Rider Accepted!", `${riderName} is on the way to pick you up.`, { type: "trip_accepted", tripId, riderName });
            break;
        }
        // Rider en route → notify passenger
        case "arriving": {
            if (!passengerId)
                break;
            const token = await getToken("users", passengerId);
            if (!token)
                break;
            await sendNotification(token, "🏍 Rider is on the way", `${riderName} is heading to ${pickup}.`, { type: "trip_arriving", tripId });
            break;
        }
        // Rider arrived at pickup → notify passenger
        case "arrived": {
            if (!passengerId)
                break;
            const token = await getToken("users", passengerId);
            if (!token)
                break;
            await sendNotification(token, "📍 Rider has arrived!", `${riderName} is waiting at ${pickup}.`, { type: "trip_arrived", tripId });
            break;
        }
        // Trip started → notify passenger
        case "ongoing": {
            if (!passengerId)
                break;
            const token = await getToken("users", passengerId);
            if (!token)
                break;
            await sendNotification(token, "🚀 Trip Started!", `Heading to ${destination}. Enjoy your ride!`, { type: "trip_ongoing", tripId });
            break;
        }
        // Trip completed → notify both
        case "completed": {
            const fare = ((_f = after.fare) !== null && _f !== void 0 ? _f : 0).toFixed(2);
            // Notify passenger
            if (passengerId) {
                const pToken = await getToken("users", passengerId);
                if (pToken) {
                    await sendNotification(pToken, "✅ Trip Completed!", `GH₵ ${fare} charged. Rate your rider!`, { type: "trip_completed", tripId, fare });
                }
            }
            // Notify rider
            if (riderId) {
                const rToken = await getToken("riders", riderId);
                if (rToken) {
                    await sendNotification(rToken, "💰 Trip Completed!", `You earned GH₵ ${fare}. Rate your passenger!`, { type: "trip_completed", tripId, fare });
                }
            }
            break;
        }
        // Trip cancelled → notify rider if they had accepted
        case "cancelled": {
            if (!riderId)
                break;
            const token = await getToken("riders", riderId);
            if (!token)
                break;
            await sendNotification(token, "❌ Ride Cancelled", "The passenger cancelled the ride request.", { type: "trip_cancelled", tripId });
            break;
        }
    }
    console.log(`Trip ${tripId}: ${oldStatus} → ${newStatus}`);
});
//# sourceMappingURL=index.js.map