# YƐRIDE – Okada Ride-Hailing Application

## Overview
YɛRide is a motorbike (Okada) ride-hailing app for Ghana, connecting passengers with verified riders via real-time GPS on a Flutter-powered mobile platform.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Notifications | Firebase Cloud Messaging |
| Maps & Navigation | Google Maps API |
| Payments | MTN MoMo, Vodafone Cash, AirtelTigo |
| Admin Panel | Web-based dashboard |

---

## Apps to Build

### 1. Passenger App
- [x] Registration & Login
- [x] Ride Booking (pickup & destination input)
- [x] Fare Estimation
- [x] Live GPS Tracking
- [x] In-app Payment
- [x] Trip History
- [x] Rate Rider

### 2. Rider App
- [x] Registration & Verification
- [x] Availability Toggle
- [x] Ride Request Alerts
- [x] Navigation System
- [x] Earnings Dashboard
- [x] Rate Passenger

### 3. Admin Dashboard (Web)
- [ ] User & Rider Management
- [ ] Trip Monitoring
- [ ] Pricing Control
- [ ] Reports & Analytics

---

## Database Collections (Firestore)

- `users` — passenger profiles
- `riders` — rider profiles + verification status
- `trips` — trip records (pickup, destination, fare, status)
- `payments` — payment records per trip
- `ratings` — rider & passenger ratings

---

## System Workflow

1. Passenger enters pickup & destination
2. App calculates distance & estimated fare
3. Nearby rider receives request notification
4. Rider accepts → real-time GPS tracking begins
5. Trip completes → payment processed
6. Both users rate each other

---

## Development Phases

### Phase 1 — UI/UX (Week 1–2)
- [x] Splash & Onboarding screens
- [x] Auth screens (Login, Register)
- [x] Passenger home screen (map + booking)
- [x] Rider home screen (map + toggle)
- [x] Trip screens (tracking, completion, rating)

### Phase 2 — Backend & Core Features (Week 3–5)
- [ ] Firebase Auth setup (email + phone)
- [ ] Firestore schema setup
- [ ] Google Maps integration
- [ ] Real-time ride matching logic
- [ ] GPS tracking (live location updates)
- [ ] Fare calculation engine
- [ ] Push notifications (FCM)
- [ ] Mobile money payment integration

### Phase 3 — Testing (Week 6)
- [ ] Real device testing (Android)
- [ ] Edge case handling
- [ ] Performance optimization

### Phase 4 — Deployment (Week 7)
- [ ] APK build & release
- [ ] Firebase production setup
- [ ] Admin dashboard deployment

---

## Security
- Firebase Auth for identity management
- HTTPS for all data transmission
- Role-based access (passenger / rider / admin)
- Rider identity verification flow
- Location validation for fraud detection

---

## Monetization
- Commission per completed ride
- Surge pricing during peak hours
- Rider subscription plans
- Featured driver promotions

---

## Current Status
- [x] Flutter project initialized
- [x] App runs on physical device (itel A667L)
- [x] Phase 1 complete
- [ ] Phase 2 in progress
