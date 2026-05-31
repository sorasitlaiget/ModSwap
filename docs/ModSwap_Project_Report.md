# ModSwap — Project Report
**Enterprise-Grade Mobile Application**
KMUTT · Faculty of Information Technology · 2025–2026

---

## Team Members

| Name | Role |
|------|------|
| Sorasit Laiget | Backend Lead · Backend Integration |
| Veerachai Sribuatim | UX/UI Design · Frontend |
| Poowrin Trijakpranee | Frontend |
| Chakkrapat Supanith | UX/UI Design · Frontend · Backend |
| Siwakon Wanichsujit | Frontend |

---

## 1. Concept and List of Functions

### Concept
**ModSwap** is a KMUTT-exclusive student-to-student marketplace mobile application that enables students to buy, sell, and swap second-hand items within the KMUTT community. Access is restricted to verified `@mail.kmutt.ac.th` email addresses, ensuring a safe and trusted campus environment.

The app addresses the common problem of students accumulating unused textbooks, electronics, and equipment between academic terms, while other students need the same items at lower prices. ModSwap creates a closed-loop circular economy within the campus.

### Key Value Propositions
- **Trust** — Only verified KMUTT students can participate
- **Convenience** — AI-powered semantic search finds items intelligently
- **Safety** — Seller ratings and deal history build community trust
- **Flexibility** — Supports sale, swap, or both listing types

### List of Functions

#### Authentication & Onboarding
| # | Function | Description |
|---|----------|-------------|
| A1 | Register | Create account with KMUTT email, verify email |
| A2 | Login | Email/password sign-in with Firebase Auth |
| A3 | Biometric Login | Face ID / Touch ID via `local_auth` |
| A4 | Complete Profile | Set display name, student ID, LINE ID after first login |
| A5 | Email Verification | Only `@mail.kmutt.ac.th` emails allowed; verified via Firebase |
| A6 | Change Password | Secure password update from settings |
| A7 | Delete Account | Soft-delete flow; removes user data |

#### Listings
| # | Function | Description |
|---|----------|-------------|
| L1 | Browse Listings | Home feed with category filter tabs |
| L2 | Semantic Search | AI-powered search using Gemini embedding-001 (768-dim cosine similarity) |
| L3 | Keyword Search | Fallback text search when semantic search is disabled |
| L4 | Category Filter | Filter by Books, Electronics, Clothes, Stationery, etc. |
| L5 | Listing Detail | Full item view: images, description, price, seller info, condition |
| L6 | Post Item | Create listing with images, price, swap preferences, condition |
| L7 | Edit Listing | Modify unpublished/published items |
| L8 | Delete Listing | Remove item from marketplace |
| L9 | My Items | View own listings by state: Draft / Published / Sold |
| L10 | Image Upload | Multi-image upload with compression to Firebase Storage |
| L11 | Mark as Sold | Record completed deal with buyer LINE ID, price, deal type |
| L12 | View Count | Track how many times each listing was viewed |

#### Social & Trust
| # | Function | Description |
|---|----------|-------------|
| S1 | Wishlist | Save/unsave listings; view saved items |
| S2 | Seller Profile | View any seller's profile, rating, listings |
| S3 | Rate Seller | Submit 1–5 star rating with review text after deal |
| S4 | View Ratings | See all ratings received on own profile |
| S5 | Pending Rating | System prompts buyer to rate seller after deal completes |

#### Notifications
| # | Function | Description |
|---|----------|-------------|
| N1 | Wishlist Notification | Alert when someone wishlists your item |
| N2 | Rating Received | Alert when you receive a new rating |
| N3 | Rate Request | Prompt buyer to rate after deal is marked complete |
| N4 | Mark Sold Reminder | Confirmation when deal is recorded |
| N5 | Price Drop | Alert when a wishlisted item's price drops |
| N6 | Trending | Recommendation for popular items in preferred categories |
| N7 | Welcome | Sent on first login |
| N8 | Email Verified | Confirmation of email verification |
| N9 | Security Alert | New device login detection |
| N10 | Password Changed | Confirmation of password update |

#### System / Settings
| # | Function | Description |
|---|----------|-------------|
| P1 | Edit Profile | Update display name, student ID, LINE ID, avatar |
| P2 | Theme Toggle | Light / Dark mode |
| P3 | Feature Flags | Firebase Remote Config controls semantic search toggle |
| P4 | Logout | Sign out and clear session |

---

## 2. User Persona

### Primary Persona

---

**Name:** Nattawut Charoensuk
**Nickname:** Net
**Age:** 20 years old
**Year:** 2nd Year
**Faculty:** Faculty of Engineering, KMUTT
**Major:** Computer Engineering

---

**Background:**
Net is a sophomore at KMUTT who lives in a student dormitory near the Bang Mod campus. He receives a monthly allowance of 6,000 THB from his parents and takes on occasional freelance web development work. He is tech-savvy, uses his phone for most transactions, and is comfortable with apps like Shopee, LINE, and Facebook Marketplace.

**Goals:**
- Find affordable second-hand engineering textbooks at the start of each semester
- Sell textbooks and equipment he no longer uses to recoup costs
- Swap his old iPad for a newer model before his 3rd year

**Frustrations:**
- Facebook Marketplace groups are full of non-KMUTT sellers; hard to coordinate meetups
- No way to verify if a seller is a real KMUTT student
- Manually browsing hundreds of listings is time-consuming
- Sellers often ghost buyers or don't reply promptly

**Tech Behavior:**
- Uses phone 6–8 hours/day
- Prefers chat (LINE) over phone calls
- Pays with PromptPay / QR code
- Takes photos of items before buying

**Quote:**
> "I want to buy second-hand items at uni safely, without worrying about being scammed — meet up right here on campus."

**Device:** iPhone 14 (iOS 17), MacBook Air M2
**Preferred Payment:** PromptPay, Cash
**Meetup Preference:** On-campus (Engineering canteen, Library, Dorm lobby)

---

### Secondary Persona

**Name:** Wanwisa Thongprasert
**Nickname:** Fah
**Age:** 22 years old
**Year:** 4th Year
**Faculty:** Faculty of Architecture and Design

**Background:**
Fah is graduating and needs to clear out 4 years' worth of architecture supplies, drawing tools, and textbooks. She wants quick sales before she moves out of her dormitory.

**Goals:**
- Sell items quickly at fair prices
- Build a seller reputation so buyers trust her listings
- Minimal friction — post item in under 5 minutes

**Frustrations:**
- No centralized KMUTT marketplace before ModSwap
- Buyers don't show up after agreeing to meet

---

## 3. User Journey Map

**Persona:** Nattawut (Net), 2nd-year Engineering student
**Goal:** Find and purchase a second-hand Calculus textbook

| Phase | Step | User Action | System Response | Emotion | Pain Point |
|-------|------|-------------|-----------------|---------|------------|
| **1. Discover** | 1.1 | Hears about ModSwap from a friend | — | Curious | — |
| | 1.2 | Downloads app from App Store | App opens to Login screen | Hopeful | Slow download on campus WiFi |
| **2. Register** | 2.1 | Taps "Register" | Registration form shown | Neutral | — |
| | 2.2 | Enters KMUTT email + password | Form validates email domain | Confident | Error if non-KMUTT email |
| | 2.3 | Checks email for verification link | Firebase sends verification email | Waiting | Email takes 1–2 min |
| | 2.4 | Taps verification link | Account verified; redirect to Complete Profile | Relieved | — |
| | 2.5 | Fills in display name, student ID, LINE ID | Profile saved; navigates to Home | Excited | — |
| **3. Browse & Search** | 3.1 | Sees home feed | Listings loaded (published state) | Engaged | Too many items, hard to find |
| | 3.2 | Types "Calculus" in search bar | Semantic search returns relevant results | Impressed | — |
| | 3.3 | Taps category "Books" | Filtered feed shows only book listings | Satisfied | — |
| | 3.4 | Taps listing "Calculus: Early Transcendentals" | Listing detail screen opens | Interested | — |
| **4. Contact & Negotiate** | 4.1 | Views listing: images, price (250 THB), seller rating | Full details shown | Positive | Wishes there were more photos |
| | 4.2 | Taps "Wishlist" heart icon | Listing saved; wishlist count increments | Committed | — |
| | 4.3 | Notes seller's LINE ID; contacts via LINE | — (outside app) | Slightly frustrated | Has to leave app to contact |
| | 4.4 | Agrees to meet at Engineering canteen | — | Excited | — |
| **5. Complete Deal** | 5.1 | Meets seller on campus; inspects item | — | Satisfied | — |
| | 5.2 | Pays 230 THB (negotiated) via PromptPay | — | Happy | — |
| | 5.3 | Seller marks listing as sold in app | Listing state → 'sold'; Deal record created | — | — |
| | 5.4 | Net receives "Deal Complete!" notification | `markSoldReminder` notification in app | Notified | — |
| **6. Rate & Return** | 6.1 | Receives "Rate Your Experience" prompt | `rateRequest` notification shown | Reminded | — |
| | 6.2 | Opens notification → Rating screen | Rating form loaded | Engaged | — |
| | 6.3 | Submits 5-star rating with comment | Rating saved; seller's avg rating updated | Accomplished | — |
| | 6.4 | Returns to browse more listings | Home feed | Loyal | — |

**Moments of Delight:**
- Semantic search correctly finds Thai-language items
- On-campus meetup reduces risk of being scammed
- Seller rating system builds trust before committing

**Moments of Friction:**
- Contact outside app (LINE) breaks the in-app flow
- Verification email delay during registration

---

## 4. Work Breakdown Structure (WBS)

```
ModSwap Mobile Application
├── 1. Project Management
│   ├── 1.1 Requirements Gathering & Analysis          [8h] — Sorasit, Veerachai
│   ├── 1.2 Sprint Planning & Backlog Grooming         [4h] — Sorasit
│   ├── 1.3 Weekly Stand-ups & Progress Tracking       [6h] — All
│   └── 1.4 Final Report & Documentation               [8h] — All
│
├── 2. UI/UX Design
│   ├── 2.1 User Research & Persona Creation           [4h] — Veerachai, Chakkrapat
│   ├── 2.2 User Journey Mapping                       [3h] — Veerachai
│   ├── 2.3 Wireframes (Lo-Fi)                         [6h] — Veerachai, Chakkrapat
│   ├── 2.4 High-Fidelity Mockups (Figma)              [10h] — Veerachai, Chakkrapat
│   └── 2.5 Design System & Component Library         [4h] — Veerachai
│
├── 3. Authentication & User Management
│   ├── 3.1 Firebase Auth Setup                        [2h] — Sorasit
│   ├── 3.2 Register / Login / Logout Flow             [6h] — Siwakon
│   ├── 3.3 Email Verification (KMUTT domain guard)    [3h] — Sorasit
│   ├── 3.4 Complete Profile Screen                    [4h] — Siwakon
│   ├── 3.5 Biometric Authentication                   [5h] — Siwakon
│   └── 3.6 Change Password / Security Settings       [3h] — Siwakon
│
├── 4. Listings Module
│   ├── 4.1 Firestore Schema Design                    [3h] — Sorasit
│   ├── 4.2 Post Item Screen (Create/Edit)             [10h] — Poowrin
│   ├── 4.3 Image Upload with Compression              [4h] — Poowrin
│   ├── 4.4 Home Feed (Browse + Category Filter)       [8h] — Poowrin
│   ├── 4.5 Listing Detail Screen                      [8h] — Chakkrapat
│   ├── 4.6 My Items Screen (Draft/Published/Sold)     [6h] — Chakkrapat
│   └── 4.7 Mark as Sold Flow                          [6h] — Chakkrapat, Sorasit
│
├── 5. Search
│   ├── 5.1 Gemini Embedding Integration               [6h] — Sorasit
│   ├── 5.2 Cloud Function: Generate Embedding         [4h] — Sorasit
│   ├── 5.3 Cosine Similarity Search Endpoint          [6h] — Sorasit
│   ├── 5.4 Search UI (Search Bar + Results)           [5h] — Poowrin
│   └── 5.5 Remote Config Feature Flag                 [2h] — Sorasit
│
├── 6. Social & Trust Features
│   ├── 6.1 Wishlist (Add/Remove + Count Badge)        [4h] — Siwakon
│   ├── 6.2 Seller Profile View                        [5h] — Chakkrapat
│   ├── 6.3 Rating System (Submit + Display)           [8h] — Poowrin, Sorasit
│   ├── 6.4 Pending Rating Flow                        [5h] — Sorasit
│   └── 6.5 Edit Profile                               [4h] — Siwakon
│
├── 7. Notifications
│   ├── 7.1 Firestore Notification Schema              [2h] — Sorasit
│   ├── 7.2 Notification Model & Types                 [3h] — Chakkrapat
│   ├── 7.3 Notification Screen (Tabs + Grouping)      [6h] — Chakkrapat
│   ├── 7.4 NotificationService (Read/Stream)          [4h] — Sorasit
│   └── 7.5 Unread Badge on Nav Bar                    [2h] — Chakkrapat
│
├── 8. Backend (Cloud Functions)
│   ├── 8.1 Express API Setup + Middleware             [4h] — Sorasit
│   ├── 8.2 Auth Middleware (Firebase Token Verify)    [2h] — Sorasit
│   ├── 8.3 Listings CRUD Endpoints                    [8h] — Sorasit
│   ├── 8.4 Deals Service (Mark as Sold + Stats)       [6h] — Sorasit
│   ├── 8.5 Ratings Service                            [4h] — Sorasit
│   ├── 8.6 Firestore Triggers (onCreate/onDelete)     [4h] — Sorasit
│   └── 8.7 Firestore Security Rules                   [4h] — Sorasit
│
└── 9. QA, Testing & Deployment
    ├── 9.1 Unit Tests (Services & Utilities)          [6h] — Sorasit
    ├── 9.2 Widget Tests                               [6h] — Poowrin
    ├── 9.3 Integration Tests                          [4h] — Poowrin
    ├── 9.4 Manual QA Testing                         [4h] — All
    ├── 9.5 Firebase Emulator Testing                  [3h] — Sorasit
    └── 9.6 Build & Deployment                         [3h] — Sorasit
```

**Total Estimated Effort: ~220 person-hours**

---

## 5. Backlog Planning

### Sprint 1 — Foundation (Week 1)
**Goal:** Project setup, authentication, core infrastructure

| ID | User Story | Priority | Points | Assignee |
|----|-----------|----------|--------|----------|
| US-01 | As a student, I want to register with my KMUTT email so that only real KMUTT students can access the app | Must | 5 | Siwakon |
| US-02 | As a user, I want to verify my KMUTT email before I can use the app | Must | 3 | Sorasit |
| US-03 | As a user, I want to complete my profile (name, student ID, LINE ID) after registration | Must | 3 | Siwakon |
| US-04 | As a user, I want to log in and log out securely | Must | 2 | Siwakon |
| US-05 | As a developer, I want Firebase Auth + Cloud Functions backend with auth middleware | Must | 5 | Sorasit |
| US-06 | As a developer, I want Firestore schema designed for users, listings, deals, notifications | Must | 3 | Sorasit |

**Sprint 1 Velocity: 21 points**

---

### Sprint 2 — Core Listings (Week 2)
**Goal:** Browse, post, and manage listings

| ID | User Story | Priority | Points | Assignee |
|----|-----------|----------|--------|----------|
| US-07 | As a seller, I want to post a listing with images, price, and description | Must | 8 | Poowrin |
| US-08 | As a buyer, I want to browse listings on the home feed | Must | 5 | Poowrin |
| US-09 | As a buyer, I want to filter listings by category | Must | 3 | Poowrin |
| US-10 | As a buyer, I want to view the full listing detail with all images | Must | 5 | Chakkrapat |
| US-11 | As a seller, I want to edit and delete my listings | Should | 3 | Chakkrapat |
| US-12 | As a seller, I want to manage my listings by state (draft/published/sold) | Should | 3 | Chakkrapat |

**Sprint 2 Velocity: 27 points**

---

### Sprint 3 — Search & Social (Week 3)
**Goal:** AI search, wishlist, seller profiles, ratings

| ID | User Story | Priority | Points | Assignee |
|----|-----------|----------|--------|----------|
| US-13 | As a buyer, I want to search for items using natural language (AI semantic search) | Must | 8 | Sorasit |
| US-14 | As a buyer, I want to save listings to my wishlist | Should | 3 | Siwakon |
| US-15 | As a buyer, I want to view a seller's profile and ratings before buying | Must | 5 | Chakkrapat |
| US-16 | As a buyer, I want to rate a seller after a deal completes | Must | 5 | Poowrin |
| US-17 | As a seller, I want to mark a deal as sold and record buyer details | Must | 5 | Chakkrapat |
| US-18 | As a developer, I want Firebase Remote Config to toggle semantic search on/off | Should | 2 | Sorasit |

**Sprint 3 Velocity: 28 points**

---

### Sprint 4 — Notifications & Security (Week 4)
**Goal:** Full notification system, biometric auth, security

| ID | User Story | Priority | Points | Assignee |
|----|-----------|----------|--------|----------|
| US-19 | As a user, I want in-app notifications grouped by category (Buyer / For You / System) | Must | 8 | Chakkrapat |
| US-20 | As a seller, I want to be notified when someone wishlists my item | Should | 3 | Sorasit |
| US-21 | As a buyer, I want to be prompted to rate a seller after a deal | Must | 3 | Sorasit |
| US-22 | As a user, I want to log in with Face ID / Touch ID for convenience | Should | 5 | Siwakon |
| US-23 | As a user, I want to change my password securely | Should | 2 | Siwakon |
| US-24 | As a user, I want to update my profile (name, avatar, LINE ID) | Should | 3 | Siwakon |

**Sprint 4 Velocity: 24 points**

---

### Sprint 5 — Polish, Testing & Deployment (Week 5)
**Goal:** QA, bug fixes, performance, documentation

| ID | User Story | Priority | Points | Assignee |
|----|-----------|----------|--------|----------|
| US-25 | As a developer, I want widget tests for core screens | Must | 5 | Poowrin |
| US-26 | As a developer, I want integration tests for auth and listing flows | Should | 5 | Poowrin |
| US-27 | As a user, I want dark/light theme toggle | Should | 2 | Veerachai |
| US-28 | As a developer, I want Firestore security rules that restrict access properly | Must | 3 | Sorasit |
| US-29 | As a team, I want all project documentation completed | Must | 5 | All |
| US-30 | As a developer, I want the app builds and runs on iOS and Android | Must | 3 | Sorasit |

**Sprint 5 Velocity: 23 points**

---

**Total Backlog: 123 story points across 30 user stories**

---

## 6. Gantt Chart

```
WEEK        │ W1 (Mar 1-7) │ W2 (Mar 8-14) │ W3 (Mar 15-21) │ W4 (Mar 22-28) │ W5 (Mar 29-Apr 4)
────────────┼──────────────┼───────────────┼────────────────┼────────────────┼──────────────────
SPRINT      │   Sprint 1   │    Sprint 2   │    Sprint 3    │    Sprint 4    │     Sprint 5
────────────┼──────────────┼───────────────┼────────────────┼────────────────┼──────────────────
Auth Setup  │ ████████████ │               │                │                │
Register/   │ ████████████ │               │                │                │
Login Flow  │              │               │                │                │
Profile     │ ██████       │               │                │                │
────────────┼──────────────┼───────────────┼────────────────┼────────────────┼──────────────────
Firebase    │ ████████████ │               │                │                │
Backend     │              │               │                │                │
────────────┼──────────────┼───────────────┼────────────────┼────────────────┼──────────────────
Post Item   │              │ ████████████  │                │                │
Home Feed   │              │ ████████████  │                │                │
Category    │              │ ██████        │                │                │
Filter      │              │               │                │                │
Listing     │              │ ████████████  │                │                │
Detail      │              │               │                │                │
My Items    │              │ ██████████    │                │                │
────────────┼──────────────┼───────────────┼────────────────┼────────────────┼──────────────────
AI Search   │              │               │ ████████████   │                │
Wishlist    │              │               │ ██████         │                │
Seller      │              │               │ ████████       │                │
Profile     │              │               │                │                │
Ratings     │              │               │ ████████████   │                │
Mark Sold   │              │               │ ████████       │                │
────────────┼──────────────┼───────────────┼────────────────┼────────────────┼──────────────────
Notif.      │              │               │                │ ████████████   │
System      │              │               │                │                │
Biometric   │              │               │                │ ████████████   │
Auth        │              │               │                │                │
Edit        │              │               │                │ ██████         │
Profile     │              │               │                │                │
────────────┼──────────────┼───────────────┼────────────────┼────────────────┼──────────────────
Widget      │              │               │                │                │ ████████████
Tests       │              │               │                │                │
Integration │              │               │                │                │ ████████
Tests       │              │               │                │                │
Firestore   │              │               │                │                │ ██████
Rules       │              │               │                │                │
Docs +      │              │               │                │                │ ████████████
Deploy      │              │               │                │                │
────────────┴──────────────┴───────────────┴────────────────┴────────────────┴──────────────────
```

**Legend:** `████` = Active development period

**Milestones:**
- **M1 (End W1):** Auth flow complete + Firebase connected
- **M2 (End W2):** Core listing CRUD working
- **M3 (End W3):** Search + Social features live
- **M4 (End W4):** Full notifications + biometric auth
- **M5 (End W5):** Tests, security rules, deployment ready

---

## 7. Precedence Diagram (Task Dependencies)

```
START
  │
  ├─── [T1] Firebase Project Setup ──────────────────────────────────────────┐
  │         (Sorasit, 2h)                                                     │
  │                                                                           │
  ├─── [T2] UI/UX Design & Figma Mockups ─────────────────────────────────┐  │
  │         (Veerachai, Chakkrapat, 10h)                                   │  │
  │                                                                        │  │
  └─── [T3] Firestore Schema Design ──────────────────┐                   │  │
            (Sorasit, 3h)                               │                   │  │
                                                        │                   │  │
                    ┌───────────────────────────────────┘                   │  │
                    ↓                                                        │  │
              [T4] Auth Backend Middleware ◄────────────────────────────────┘  │
              (Sorasit, 4h)                                                     │
                    │                                                           │
        ┌───────────┤                                                           │
        │           │                                                           │
        ↓           ↓                                                           │
  [T5] Register   [T6] Complete Profile Screen ◄──────────────────────────────┘
  /Login Flow     (Siwakon, 4h)
  (Siwakon, 6h)
        │           │
        └─────┬─────┘
              │
              ↓
         [T7] Listings CRUD Backend
         (Sorasit, 8h)
              │
        ┌─────┴──────────────────┐
        ↓                        ↓
  [T8] Post Item Screen    [T9] Home Feed Screen
  (Poowrin, 10h)           (Poowrin, 8h)
        │                        │
        ↓                        ↓
  [T10] My Items Screen    [T11] Listing Detail
  (Chakkrapat, 6h)         (Chakkrapat, 8h)
        │                        │
        └─────────┬──────────────┘
                  │
        ┌─────────┴─────────────────────┐
        ↓                               ↓
  [T12] Mark as Sold            [T13] Gemini AI Search
  (Chakkrapat, Sorasit, 6h)     (Sorasit, 12h)
        │
        ↓
  [T14] Deals Service Backend
  (Sorasit, 6h)
        │
        ├────────────────────────────────┐
        ↓                                ↓
  [T15] Rating System             [T16] Wishlist
  (Poowrin, Sorasit, 8h)          (Siwakon, 4h)
        │
        ↓
  [T17] Notifications System
  (Chakkrapat, Sorasit, 8h)
        │
        ├───────────────────────────────────┐
        ↓                                   ↓
  [T18] Biometric Auth               [T19] Edit Profile
  (Siwakon, 5h)                      (Siwakon, 4h)
        │
        └──────────┬────────────────────────┘
                   │
                   ↓
            [T20] Firestore Security Rules
            (Sorasit, 4h)
                   │
                   ↓
            [T21] Widget & Integration Tests
            (Poowrin, 10h)
                   │
                   ↓
            [T22] QA & Bug Fixes
            (All, 4h)
                   │
                   ↓
            [T23] Build & Deploy
            (Sorasit, 3h)
                   │
                  END
```

**Critical Path:**
`T1 → T4 → T5 → T7 → T8 → T10 → T12 → T14 → T15 → T17 → T18 → T20 → T21 → T22 → T23`

**Critical Path Duration:** ~90 hours

**Parallel Tracks:**
- T2 (UI/UX Design) runs parallel to T1, T3, T4
- T13 (AI Search) runs parallel to T12 (Mark as Sold)
- T16 (Wishlist) runs parallel to T15 (Ratings)
- T19 (Edit Profile) runs parallel to T18 (Biometric Auth)

---

## 8. Conceptual Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ModSwap Mobile Application                          │
│                          Conceptual Architecture                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────┐     ┌───────────────────────┐     ┌────────────────┐
│   PRESENTATION LAYER  │     │    DOMAIN LAYER        │     │  DATA LAYER    │
│                       │     │                        │     │                │
│  ┌──────────────────┐ │     │  ┌──────────────────┐ │     │ ┌────────────┐ │
│  │     Screens      │ │     │  │   Use Cases       │ │     │ │Repositories│ │
│  │                  │ │     │  │                   │ │     │ │            │ │
│  │ • HomeScreen     │ │◄───►│  │ • BrowseListings  │ │◄───►│ │ Listings   │ │
│  │ • ListingDetail  │ │     │  │ • SearchListings  │ │     │ │ Users      │ │
│  │ • PostItemScreen │ │     │  │ • MarkAsSold      │ │     │ │ Deals      │ │
│  │ • ProfileScreen  │ │     │  │ • SubmitRating    │ │     │ │ Ratings    │ │
│  │ • NotifScreen    │ │     │  │ • SendNotif       │ │     │ │ Wishlist   │ │
│  │ • AuthScreens    │ │     │  │ • AuthUser        │ │     │ │ Notifs     │ │
│  └──────────────────┘ │     │  └──────────────────┘ │     │ └────────────┘ │
│                       │     │                        │     │                │
│  ┌──────────────────┐ │     │  ┌──────────────────┐ │     │ ┌────────────┐ │
│  │  State (Provider)│ │     │  │   Entities        │ │     │ │Data Sources│ │
│  │                  │ │     │  │                   │ │     │ │            │ │
│  │ • AuthState      │ │     │  │ • User            │ │     │ │ Firestore  │ │
│  │ • ThemeProvider  │ │     │  │ • Listing         │ │     │ │ Firebase   │ │
│  │ • NotifProvider  │ │     │  │ • Deal            │ │     │ │   Auth     │ │
│  └──────────────────┘ │     │  │ • Rating          │ │     │ │ Firebase   │ │
│                       │     │  │ • Notification    │ │     │ │  Storage   │ │
│  ┌──────────────────┐ │     │  └──────────────────┘ │     │ │ Cloud Func │ │
│  │    Widgets       │ │     │                        │     │ └────────────┘ │
│  │ (Reusable UI)    │ │     │  ┌──────────────────┐ │     │                │
│  └──────────────────┘ │     │  │  Repo Interfaces  │ │     │ ┌────────────┐ │
│                       │     │  │  (Abstract)       │ │     │ │  External  │ │
└───────────────────────┘     │  └──────────────────┘ │     │ │  Services  │ │
                              └───────────────────────┘     │ │            │ │
                                                            │ │ • Gemini AI│ │
                                                            │ │ • Remote   │ │
                                                            │ │   Config   │ │
                                                            │ └────────────┘ │
                                                            └────────────────┘

                    ┌──────────────────────────────────────┐
                    │         BACKEND LAYER                 │
                    │    Firebase Cloud Functions           │
                    │          (TypeScript)                 │
                    │                                       │
                    │  ┌─────────────┐  ┌───────────────┐  │
                    │  │  REST API   │  │   Triggers    │  │
                    │  │  (Express)  │  │  (Firestore)  │  │
                    │  │             │  │               │  │
                    │  │ /listings   │  │ onCreate:user │  │
                    │  │ /deals      │  │ onCreate:     │  │
                    │  │ /ratings    │  │   listing     │  │
                    │  │ /users      │  │ onDelete:     │  │
                    │  │ /search     │  │   listing     │  │
                    │  └─────────────┘  └───────────────┘  │
                    │                                       │
                    │  ┌─────────────────────────────────┐  │
                    │  │    Security Middleware           │  │
                    │  │  Firebase ID Token Validation   │  │
                    │  └─────────────────────────────────┘  │
                    └──────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility |
|-------|---------------|
| **Presentation** | Flutter widgets and screens; user interaction only; no business logic |
| **Domain** | Use cases (business rules); entities (data models); repository interfaces |
| **Data** | Concrete repository implementations; Firebase/API adapters |
| **Backend** | Server-side business logic; auth enforcement; AI search; Firestore triggers |

### Key Architectural Decisions
- **Separation of Concerns**: Each layer only depends on the layer directly beneath it
- **Dependency Inversion**: Domain layer defines interfaces; Data layer implements them
- **Feature-Based Organization**: Code organized by feature module (listings, deals, auth, etc.)
- **Server-Side Authority**: All sensitive operations (mark as sold, create deal) validated on Cloud Functions, never trusted from client alone

---

## 9. Implementation Architecture Diagram

```
my_final_app/
├── lib/
│   ├── main.dart                          ← App entry point, Provider setup
│   ├── firebase_options.dart              ← Auto-generated by FlutterFire CLI
│   │
│   ├── config/
│   │   ├── api_config.dart                ← Base URLs, emulator toggle
│   │   └── constants.dart                 ← App-wide constants
│   │
│   ├── theme/
│   │   ├── app_colors.dart                ← Color palette (light + dark)
│   │   └── app_theme_ext.dart             ← ThemeExtension for custom tokens
│   │
│   ├── models/                            ← Plain Dart data classes
│   │   ├── listing_model.dart             ← Listing (fromJson/toJson/copyWith)
│   │   ├── user_model.dart                ← UserProfile
│   │   ├── deal_model.dart                ← Deal record
│   │   ├── rating_model.dart              ← Rating submission
│   │   ├── notification_model.dart        ← AppNotification + enums
│   │   └── pending_rating_model.dart      ← Pending rating prompt
│   │
│   ├── providers/                         ← ChangeNotifier state managers
│   │   ├── auth_state.dart                ← AuthStatus FSM (initializing→authenticated)
│   │   ├── theme_provider.dart            ← Light/Dark theme toggle
│   │   └── notification_provider.dart     ← Notification stream + unread count
│   │
│   ├── services/                          ← Firebase/API wrappers
│   │   ├── auth_service.dart              ← Firebase Auth operations
│   │   ├── api_service.dart               ← Dio HTTP client wrapper
│   │   ├── listings_service.dart          ← Listing CRUD via Cloud Functions
│   │   ├── deals_service.dart             ← Mark as sold, get deal
│   │   ├── rating_service.dart            ← Submit rating, pending ratings
│   │   ├── notification_service.dart      ← Write notification to Firestore
│   │   ├── wishlist_service.dart          ← Add/remove wishlist items
│   │   └── remote_config_service.dart     ← Firebase Remote Config flags
│   │
│   ├── screen/                            ← Full-page screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── verify_email_screen.dart
│   │   │   └── complete_profile_screen.dart
│   │   ├── home_screen.dart               ← Feed + search + category filter
│   │   ├── listing_detail_screen.dart     ← Full listing view + mark as sold
│   │   ├── post_item_screen.dart          ← Create/edit listing
│   │   ├── my_items_screen.dart           ← Seller's own listings
│   │   ├── notification_screen.dart       ← Tabbed notifications
│   │   ├── wishlist_screen.dart           ← Saved listings
│   │   ├── profile_screen.dart            ← Own profile view
│   │   ├── seller_profile_screen.dart     ← Other seller's profile
│   │   ├── edit_profile_screen.dart       ← Edit name, avatar, LINE ID
│   │   ├── change_password_screen.dart    ← Password update
│   │   └── rating_screen.dart             ← Submit rating for seller
│   │
│   └── widgets/                           ← Reusable UI components
│       ├── listing_card.dart              ← Card displayed in feed
│       ├── category_filter_bar.dart       ← Horizontal category tabs
│       ├── rating_stars.dart              ← Star rating display widget
│       ├── notification_tile.dart         ← Single notification row
│       └── image_picker_grid.dart         ← Multi-image picker UI
│
modswap_backend/functions/src/
├── config/
│   ├── firebase.config.ts                 ← Firebase Admin SDK init
│   └── constants.ts                       ← Collection/subcollection names
│
├── core/
│   └── errors/
│       └── app-error.ts                   ← Typed errors (NotFound, Forbidden, etc.)
│
├── middleware/
│   ├── auth.middleware.ts                 ← Firebase ID token verification
│   ├── validation.middleware.ts           ← Zod schema validation
│   └── error-handler.middleware.ts        ← Global Express error handler
│
├── modules/                               ← Feature modules
│   ├── listings/
│   │   ├── listings.controller.ts
│   │   ├── listings.service.ts
│   │   ├── listings.repository.ts
│   │   └── listings.types.ts
│   ├── deals/
│   │   ├── deals.controller.ts
│   │   ├── deals.service.ts
│   │   ├── deals.repository.ts
│   │   └── deals.types.ts
│   ├── ratings/
│   │   ├── ratings.controller.ts
│   │   ├── ratings.service.ts
│   │   └── ratings.repository.ts
│   ├── search/
│   │   ├── search.controller.ts
│   │   └── search.service.ts              ← Gemini embedding + cosine similarity
│   └── users/
│       ├── users.controller.ts
│       ├── users.service.ts
│       └── users.repository.ts
│
├── triggers/
│   ├── on-user-create.trigger.ts          ← Send welcome notification
│   ├── on-listing-create.trigger.ts       ← Generate Gemini embedding
│   └── on-listing-delete.trigger.ts       ← Cleanup Storage images
│
└── utils/
    ├── notification.util.ts               ← Write to users/{uid}/notifications/
    └── logger.util.ts                     ← Structured logging
```

### Data Flow: Post a Listing

```
User taps "Publish"
      │
      ▼
PostItemScreen
      │ calls
      ▼
ListingsService.createListing(dto)
      │ HTTP POST via Dio
      ▼
Cloud Function: POST /api/listings
      │
      ├── authMiddleware: verify Firebase ID token
      ├── validationMiddleware: Zod schema check
      ├── ListingsController.create()
      │       │
      │       ▼
      │   ListingsService.createListing()
      │       │
      │       ▼
      │   ListingsRepository.create()  ──► Firestore: listings/{id}
      │
      └── Firestore Trigger: onListingCreate
              │
              ▼
          Generate Gemini embedding (768-dim vector)
              │
              ▼
          Store embedding in listings/{id}.embedding
```

### Data Flow: Semantic Search

```
User types in search bar
      │
      ▼
HomeScreen → ListingsService.semanticSearch(query)
      │
      ▼
Remote Config: enable_semantic_search == true ?
      │                    │
     YES                   NO
      │                    │
      ▼                    ▼
Cloud Function:      Keyword filter on
POST /api/search     existing listings
      │
      ├── Embed query with Gemini embedding-001
      ├── Fetch all listing embeddings from Firestore
      ├── Compute cosine similarity
      ├── Filter: similarity >= 0.60
      └── Return ranked results
              │
              ▼
        HomeScreen renders results
```

### State Management Flow

```
Firebase Auth State Change
      │
      ▼
AuthState (ChangeNotifier)
      │
      ├── status = AuthStatus.initializing
      ├── status = AuthStatus.unauthenticated
      ├── status = AuthStatus.emailUnverified
      ├── status = AuthStatus.profileIncomplete
      └── status = AuthStatus.authenticated
                        │
                        ▼
              main.dart Consumer<AuthState>
                        │
                  Route to correct screen
```

---

*Document prepared by ModSwap Team · KMUTT · 2025–2026*
*Sorasit Laiget · Veerachai Sribuatim · Poowrin Trijakpranee · Chakkrapat Supanith · Siwakon Wanichsujit*
