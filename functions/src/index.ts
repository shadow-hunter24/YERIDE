import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helper: send FCM to a single token ───────────────────────────────────────
async function sendNotification(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data: data ?? {},
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "yeride_trips",
        },
      },
    });
  } catch (err) {
    console.error("FCM send error:", err);
  }
}

// ─── Helper: get FCM token from a collection doc ──────────────────────────────
async function getToken(
  collection: string,
  uid: string
): Promise<string | null> {
  const doc = await db.collection(collection).doc(uid).get();
  return (doc.data()?.fcmToken as string) ?? null;
}

// ─────────────────────────────────────────────────────────────────────────────
// FUNCTION 1: New trip created → notify the assigned rider
// ─────────────────────────────────────────────────────────────────────────────
export const onTripCreated = onDocumentCreated(
  "trips/{tripId}",
  async (event) => {
    const trip = event.data?.data();
    if (!trip) return;

    const assignedRiderId = trip.assignedRiderId as string | null;
    if (!assignedRiderId) return;

    const token = await getToken("riders", assignedRiderId);
    if (!token) {
      console.log(`No FCM token for rider ${assignedRiderId}`);
      return;
    }

    const pickup      = trip.pickupAddress      as string ?? "Unknown";
    const destination = trip.destinationAddress as string ?? "Unknown";
    const fare        = (trip.fare as number ?? 0).toFixed(2);

    await sendNotification(
      token,
      "🏍 New Ride Request!",
      `${pickup} → ${destination} · GH₵ ${fare}`,
      {
        type:   "new_trip",
        tripId: event.params.tripId,
        pickup,
        destination,
        fare,
      }
    );

    console.log(`Notified rider ${assignedRiderId} of new trip ${event.params.tripId}`);
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// FUNCTION 2: Trip status updated → notify relevant party
// ─────────────────────────────────────────────────────────────────────────────
export const onTripStatusChanged = onDocumentUpdated(
  "trips/{tripId}",
  async (event) => {
    const before = event.data?.before.data();
    const after  = event.data?.after.data();
    if (!before || !after) return;

    const oldStatus = before.status as string;
    const newStatus = after.status  as string;

    // Only act when status actually changed
    if (oldStatus === newStatus) return;

    const tripId      = event.params.tripId;
    const passengerId = after.passengerId      as string | null;
    const riderId     = after.riderId          as string | null;
    const pickup      = after.pickupAddress    as string ?? "Unknown";
    const destination = after.destinationAddress as string ?? "Unknown";
    const riderName   = after.riderName        as string ?? "Your rider";

    switch (newStatus) {

      // Rider accepted → notify passenger
      case "accepted": {
        if (!passengerId) break;
        const token = await getToken("users", passengerId);
        if (!token) break;
        await sendNotification(
          token,
          "✅ Rider Accepted!",
          `${riderName} is on the way to pick you up.`,
          { type: "trip_accepted", tripId, riderName }
        );
        break;
      }

      // Rider en route → notify passenger
      case "arriving": {
        if (!passengerId) break;
        const token = await getToken("users", passengerId);
        if (!token) break;
        await sendNotification(
          token,
          "🏍 Rider is on the way",
          `${riderName} is heading to ${pickup}.`,
          { type: "trip_arriving", tripId }
        );
        break;
      }

      // Rider arrived at pickup → notify passenger
      case "arrived": {
        if (!passengerId) break;
        const token = await getToken("users", passengerId);
        if (!token) break;
        await sendNotification(
          token,
          "📍 Rider has arrived!",
          `${riderName} is waiting at ${pickup}.`,
          { type: "trip_arrived", tripId }
        );
        break;
      }

      // Trip started → notify passenger
      case "ongoing": {
        if (!passengerId) break;
        const token = await getToken("users", passengerId);
        if (!token) break;
        await sendNotification(
          token,
          "🚀 Trip Started!",
          `Heading to ${destination}. Enjoy your ride!`,
          { type: "trip_ongoing", tripId }
        );
        break;
      }

      // Trip completed → notify both
      case "completed": {
        const fare = (after.fare as number ?? 0).toFixed(2);
        // Notify passenger
        if (passengerId) {
          const pToken = await getToken("users", passengerId);
          if (pToken) {
            await sendNotification(
              pToken,
              "✅ Trip Completed!",
              `GH₵ ${fare} charged. Rate your rider!`,
              { type: "trip_completed", tripId, fare }
            );
          }
        }
        // Notify rider
        if (riderId) {
          const rToken = await getToken("riders", riderId);
          if (rToken) {
            await sendNotification(
              rToken,
              "💰 Trip Completed!",
              `You earned GH₵ ${fare}. Rate your passenger!`,
              { type: "trip_completed", tripId, fare }
            );
          }
        }
        break;
      }

      // Trip cancelled → notify rider if they had accepted
      case "cancelled": {
        if (!riderId) break;
        const token = await getToken("riders", riderId);
        if (!token) break;
        await sendNotification(
          token,
          "❌ Ride Cancelled",
          "The passenger cancelled the ride request.",
          { type: "trip_cancelled", tripId }
        );
        break;
      }
    }

    console.log(`Trip ${tripId}: ${oldStatus} → ${newStatus}`);
  }
);
