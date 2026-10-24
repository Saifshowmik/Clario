# Clario 135-Screen Implementation Tracker

Source of truth: `Clario-all-135-screens.pdf` (135 numbered designs across 140 PDF pages).
Branch: `feature/full-platform-recovery`.
Status definitions: **Not started** = no implementation verified; **In progress** = partially implemented; **Implemented** = built; **Verified** = tested against design and workflow.

Do not mark a screen implemented merely because a link or placeholder exists. A screen is verified only after responsive visual review, functional checks, permission checks where relevant, and regression tests.

| # | Designed screen | Route / workflow mapping | Status | Acceptance notes |
|---:|---|---|---|
| 1 | Homepage | TBD | Not started | Map to PDF page 6; verify actual PDF page before implementation. |
| 2 | Brand board | TBD | Not started | Map to PDF page 7; verify actual PDF page before implementation. |
| 3 | Customer · Sign up & Log in | TBD | Not started | Map to PDF page 8; verify actual PDF page before implementation. |
| 4 | Admin · Sign-in (separate route) | TBD | Not started | Map to PDF page 9; verify actual PDF page before implementation. |
| 5 | Design system · Foundations | TBD | Not started | Map to PDF page 10; verify actual PDF page before implementation. |
| 6 | Design system · Components | TBD | Not started | Map to PDF page 11; verify actual PDF page before implementation. |
| 7 | Customer · Verify & recover | TBD | Not started | Map to PDF page 12; verify actual PDF page before implementation. |
| 8 | Customer · Onboarding quiz | TBD | Not started | Map to PDF page 13; verify actual PDF page before implementation. |
| 9 | Customer · Dashboard | TBD | Not started | Map to PDF page 14; verify actual PDF page before implementation. |
| 10 | Customer · My Profiles | `#profile` / Profile Studio | In progress | Editable display name, username, bio, interests and visibility preference; privilege fields excluded. Private avatar/cover uploads and removal use signed previews and owner-scoped storage policies (migration 006); storage migration/runtime verification and design-specific responsive review remain. Map to PDF page 15; verify actual PDF page before implementation. |
| 11 | Mobile · Menu & bottom nav | TBD | Not started | Map to PDF page 16; verify actual PDF page before implementation. |
| 12 | Customer · AI Decision Studio | `#decide` + Deep Think board | In progress | Existing decision form remains; Deep Think module is wired but not runtime-verified. Map to PDF page 17; verify actual PDF page before implementation. |
| 13 | Admin · Dashboard | `#admin` + Deep Think review queue | In progress | Existing owner console remains; Deep Think queue requires staging role and browser tests. Map to PDF page 18; verify actual PDF page before implementation. |
| 14 | Customer · Recommendation results | TBD | Not started | Map to PDF page 19; verify actual PDF page before implementation. |
| 15 | Customer · Life Partner / Match questions | TBD | Not started | Map to PDF page 20; verify actual PDF page before implementation. |
| 16 | Customer · Settings & Privacy | TBD | Not started | Map to PDF page 21; verify actual PDF page before implementation. |
| 17 | Public · Pricing | TBD | Not started | Map to PDF page 22; verify actual PDF page before implementation. |
| 18 | Customer · Upgrade & payments | TBD | Not started | Map to PDF page 23; verify actual PDF page before implementation. |
| 19 | Public · Community forum | `#social` / Social Studio | In progress | Text posts, 24-hour text stories, follow requests, block/mute, post/user reports, and owner moderation UI exist; media, full comments/shares, responsive visual comparison, and runtime verification remain. Map to PDF page 24; verify actual PDF page before implementation. |
| 20 | Public · Expert Blog | TBD | Not started | Map to PDF page 25; verify actual PDF page before implementation. |
| 21 | Public · About Clario | TBD | Not started | Map to PDF page 26; verify actual PDF page before implementation. |
| 22 | Public · Contact & Support | TBD | Not started | Map to PDF page 27; verify actual PDF page before implementation. |
| 23 | Public · Help Center | TBD | Not started | Map to PDF page 28; verify actual PDF page before implementation. |
| 24 | Tablet · Sidebar as icon rail | TBD | Not started | Map to PDF page 29; verify actual PDF page before implementation. |
| 25 | Tablet · Menu open (Esc or tap outside closes) | TBD | Not started | Map to PDF page 30; verify actual PDF page before implementation. |
| 26 | Public · Article page | TBD | Not started | Map to PDF page 31; verify actual PDF page before implementation. |
| 27 | Public · Forum thread with replies | TBD | Not started | Map to PDF page 32; verify actual PDF page before implementation. |
| 28 | Public · Privacy Policy | TBD | Not started | Map to PDF page 33; verify actual PDF page before implementation. |
| 29 | Public · Terms of Service | TBD | Not started | Map to PDF page 34; verify actual PDF page before implementation. |
| 30 | Customer · Renewals & refunds | TBD | Not started | Map to PDF page 35; verify actual PDF page before implementation. |
| 31 | Arabic · Homepage (right to left) | TBD | Not started | Map to PDF page 36; verify actual PDF page before implementation. |
| 32 | Spanish · Homepage | TBD | Not started | Map to PDF page 37; verify actual PDF page before implementation. |
| 33 | German · Homepage | TBD | Not started | Map to PDF page 38; verify actual PDF page before implementation. |
| 34 | Japanese · Homepage | TBD | Not started | Map to PDF page 39; verify actual PDF page before implementation. |
| 35 | Korean · Homepage | TBD | Not started | Map to PDF page 40; verify actual PDF page before implementation. |
| 36 | Chinese · Homepage | TBD | Not started | Map to PDF page 41; verify actual PDF page before implementation. |
| 37 | Hindi · Homepage | TBD | Not started | Map to PDF page 42; verify actual PDF page before implementation. |
| 38 | Bangla · Homepage | TBD | Not started | Map to PDF page 43; verify actual PDF page before implementation. |
| 39 | Spanish · Sign up & Log in | TBD | Not started | Map to PDF page 44; verify actual PDF page before implementation. |
| 40 | German · Sign up & Log in | TBD | Not started | Map to PDF page 45; verify actual PDF page before implementation. |
| 41 | Japanese · Sign up & Log in | TBD | Not started | Map to PDF page 46; verify actual PDF page before implementation. |
| 42 | Korean · Sign up & Log in | TBD | Not started | Map to PDF page 47; verify actual PDF page before implementation. |
| 43 | Chinese · Sign up & Log in | TBD | Not started | Map to PDF page 48; verify actual PDF page before implementation. |
| 44 | Hindi · Sign up & Log in | TBD | Not started | Map to PDF page 49; verify actual PDF page before implementation. |
| 45 | Bangla · Sign up & Log in | TBD | Not started | Map to PDF page 50; verify actual PDF page before implementation. |
| 46 | Arabic · Sign up & Log in | TBD | Not started | Map to PDF page 51; verify actual PDF page before implementation. |
| 47 | Spanish · Verify & recover | TBD | Not started | Map to PDF page 52; verify actual PDF page before implementation. |
| 48 | German · Verify & recover | TBD | Not started | Map to PDF page 53; verify actual PDF page before implementation. |
| 49 | Japanese · Verify & recover | TBD | Not started | Map to PDF page 54; verify actual PDF page before implementation. |
| 50 | Korean · Verify & recover | TBD | Not started | Map to PDF page 55; verify actual PDF page before implementation. |
| 51 | Chinese · Verify & recover | TBD | Not started | Map to PDF page 56; verify actual PDF page before implementation. |
| 52 | Hindi · Verify & recover | TBD | Not started | Map to PDF page 57; verify actual PDF page before implementation. |
| 53 | Bangla · Verify & recover | TBD | Not started | Map to PDF page 58; verify actual PDF page before implementation. |
| 54 | Arabic · Verify & recover | TBD | Not started | Map to PDF page 59; verify actual PDF page before implementation. |
| 55 | Spanish · Onboarding quiz | TBD | Not started | Map to PDF page 60; verify actual PDF page before implementation. |
| 56 | German · Onboarding quiz | TBD | Not started | Map to PDF page 61; verify actual PDF page before implementation. |
| 57 | Japanese · Onboarding quiz | TBD | Not started | Map to PDF page 62; verify actual PDF page before implementation. |
| 58 | Korean · Onboarding quiz | TBD | Not started | Map to PDF page 63; verify actual PDF page before implementation. |
| 59 | Chinese · Onboarding quiz | TBD | Not started | Map to PDF page 64; verify actual PDF page before implementation. |
| 60 | Arabic · Onboarding quiz | TBD | Not started | Map to PDF page 65; verify actual PDF page before implementation. |
| 61 | Hindi · Onboarding quiz | TBD | Not started | Map to PDF page 66; verify actual PDF page before implementation. |
| 62 | Bangla · Onboarding quiz | TBD | Not started | Map to PDF page 67; verify actual PDF page before implementation. |
| 63 | Customer · Decision Categories | TBD | Not started | Map to PDF page 68; verify actual PDF page before implementation. |
| 64 | Customer · Saved Decisions | TBD | Not started | Map to PDF page 69; verify actual PDF page before implementation. |
| 65 | Customer · Decision History | TBD | Not started | Map to PDF page 70; verify actual PDF page before implementation. |
| 66 | Customer · Goals & Next Steps | TBD | Not started | Map to PDF page 71; verify actual PDF page before implementation. |
| 67 | Customer · Notifications | TBD | Not started | Map to PDF page 72; verify actual PDF page before implementation. |
| 68 | Customer · Matches | TBD | Not started | Map to PDF page 73; verify actual PDF page before implementation. |
| 69 | Admin · Support inbox | TBD | Not started | Map to PDF page 74; verify actual PDF page before implementation. |
| 70 | Admin · Customer detail | TBD | Not started | Map to PDF page 75; verify actual PDF page before implementation. |
| 71 | Admin · Content & FAQs | TBD | Not started | Map to PDF page 76; verify actual PDF page before implementation. |
| 72 | Admin · Categories & templates | TBD | Not started | Map to PDF page 77; verify actual PDF page before implementation. |
| 73 | Customer · Serious Mode | TBD | Not started | Map to PDF page 78; verify actual PDF page before implementation. |
| 74 | Customer · Personal colour themes | TBD | Not started | Map to PDF page 79; verify actual PDF page before implementation. |
| 75 | Public · 404 and error pages | TBD | Not started | Map to PDF page 80; verify actual PDF page before implementation. |
| 76 | Public · Cookie banner | TBD | Not started | Map to PDF page 81; verify actual PDF page before implementation. |
| 77 | Customer · Education & Career profile | TBD | Not started | Map to PDF page 82; verify actual PDF page before implementation. |
| 78 | Customer · Finance & Budget profile | TBD | Not started | Map to PDF page 83; verify actual PDF page before implementation. |
| 79 | Customer · Business & Projects profile | TBD | Not started | Map to PDF page 84; verify actual PDF page before implementation. |
| 80 | Customer · Lifestyle & Goals profile | TBD | Not started | Map to PDF page 85; verify actual PDF page before implementation. |
| 81 | Emails | TBD | Not started | Map to PDF page 86; verify actual PDF page before implementation. |
| 82 | Phone app screens | TBD | Not started | Map to PDF page 87; verify actual PDF page before implementation. |
| 83 | Bangla · Dashboard | TBD | Not started | Map to PDF page 88; verify actual PDF page before implementation. |
| 84 | Hindi · Dashboard | TBD | Not started | Map to PDF page 89; verify actual PDF page before implementation. |
| 85 | Arabic · Dashboard | TBD | Not started | Map to PDF page 90; verify actual PDF page before implementation. |
| 86 | Spanish · Dashboard | TBD | Not started | Map to PDF page 91; verify actual PDF page before implementation. |
| 87 | German · Dashboard | TBD | Not started | Map to PDF page 92; verify actual PDF page before implementation. |
| 88 | Japanese · Dashboard | TBD | Not started | Map to PDF page 93; verify actual PDF page before implementation. |
| 89 | Korean · Dashboard | TBD | Not started | Map to PDF page 94; verify actual PDF page before implementation. |
| 90 | Chinese · Dashboard | TBD | Not started | Map to PDF page 95; verify actual PDF page before implementation. |
| 91 | Spanish · AI Decision Studio | TBD | Not started | Map to PDF page 96; verify actual PDF page before implementation. |
| 92 | Arabic · AI Decision Studio | TBD | Not started | Map to PDF page 97; verify actual PDF page before implementation. |
| 93 | Hindi · AI Decision Studio | TBD | Not started | Map to PDF page 98; verify actual PDF page before implementation. |
| 94 | Bangla · AI Decision Studio | TBD | Not started | Map to PDF page 99; verify actual PDF page before implementation. |
| 95 | German · AI Decision Studio | TBD | Not started | Map to PDF page 100; verify actual PDF page before implementation. |
| 96 | Japanese · AI Decision Studio | TBD | Not started | Map to PDF page 101; verify actual PDF page before implementation. |
| 97 | Korean · AI Decision Studio | TBD | Not started | Map to PDF page 102; verify actual PDF page before implementation. |
| 98 | Chinese · AI Decision Studio | TBD | Not started | Map to PDF page 103; verify actual PDF page before implementation. |
| 99 | Spanish · Recommendation results | TBD | Not started | Map to PDF page 104; verify actual PDF page before implementation. |
| 100 | Arabic · Recommendation results | TBD | Not started | Map to PDF page 105; verify actual PDF page before implementation. |
| 101 | Hindi · Recommendation results | TBD | Not started | Map to PDF page 106; verify actual PDF page before implementation. |
| 102 | Bangla · Recommendation results | TBD | Not started | Map to PDF page 107; verify actual PDF page before implementation. |
| 103 | German · Recommendation results | TBD | Not started | Map to PDF page 108; verify actual PDF page before implementation. |
| 104 | Japanese · Recommendation results | TBD | Not started | Map to PDF page 109; verify actual PDF page before implementation. |
| 105 | Korean · Recommendation results | TBD | Not started | Map to PDF page 110; verify actual PDF page before implementation. |
| 106 | Chinese · Recommendation results | TBD | Not started | Map to PDF page 111; verify actual PDF page before implementation. |
| 107 | Spanish · Settings & Privacy | TBD | Not started | Map to PDF page 112; verify actual PDF page before implementation. |
| 108 | Spanish · My Profiles | TBD | Not started | Map to PDF page 113; verify actual PDF page before implementation. |
| 109 | Arabic · Settings & Privacy | TBD | Not started | Map to PDF page 114; verify actual PDF page before implementation. |
| 110 | Arabic · My Profiles | TBD | Not started | Map to PDF page 115; verify actual PDF page before implementation. |
| 111 | Hindi · Settings & Privacy | TBD | Not started | Map to PDF page 116; verify actual PDF page before implementation. |
| 112 | Hindi · My Profiles | TBD | Not started | Map to PDF page 117; verify actual PDF page before implementation. |
| 113 | Bangla · Settings & Privacy | TBD | Not started | Map to PDF page 118; verify actual PDF page before implementation. |
| 114 | Bangla · My Profiles | TBD | Not started | Map to PDF page 119; verify actual PDF page before implementation. |
| 115 | German · Settings & Privacy | TBD | Not started | Map to PDF page 120; verify actual PDF page before implementation. |
| 116 | German · My Profiles | TBD | Not started | Map to PDF page 121; verify actual PDF page before implementation. |
| 117 | Japanese · Settings & Privacy | TBD | Not started | Map to PDF page 122; verify actual PDF page before implementation. |
| 118 | Japanese · My Profiles | TBD | Not started | Map to PDF page 123; verify actual PDF page before implementation. |
| 119 | Korean · Settings & Privacy | TBD | Not started | Map to PDF page 124; verify actual PDF page before implementation. |
| 120 | Korean · My Profiles | TBD | Not started | Map to PDF page 125; verify actual PDF page before implementation. |
| 121 | Chinese · Settings & Privacy | TBD | Not started | Map to PDF page 126; verify actual PDF page before implementation. |
| 122 | Chinese · My Profiles | TBD | Not started | Map to PDF page 127; verify actual PDF page before implementation. |
| 123 | Clario Mind · Welcome, age, consent and privacy | TBD | Not started | Map to PDF page 128; verify actual PDF page before implementation. |
| 124 | Clario Mind · Companion chat | TBD | Not started | Map to PDF page 129; verify actual PDF page before implementation. |
| 125 | Clario Mind · Crisis pathway | TBD | Not started | Map to PDF page 130; verify actual PDF page before implementation. |
| 126 | Clario Mind · Volunteer application | TBD | Not started | Map to PDF page 131; verify actual PDF page before implementation. |
| 127 | Clario Mind · Admin: volunteer review | TBD | Not started | Map to PDF page 132; verify actual PDF page before implementation. |
| 128 | Clario Mind · Volunteer workspace | TBD | Not started | Map to PDF page 133; verify actual PDF page before implementation. |
| 129 | Clario Mind · Talk to a volunteer professional | TBD | Not started | Map to PDF page 134; verify actual PDF page before implementation. |
| 130 | Clario Mind · Exercises and check-ins | TBD | Not started | Map to PDF page 135; verify actual PDF page before implementation. |
| 131 | Clario Mind · Mood and journal | TBD | Not started | Map to PDF page 136; verify actual PDF page before implementation. |
| 132 | Clario Mind · Safety plan, help and professionals | TBD | Not started | Map to PDF page 137; verify actual PDF page before implementation. |
| 133 | Clario Mind · Privacy and data | TBD | Not started | Map to PDF page 138; verify actual PDF page before implementation. |
| 134 | Clario Mind · Admin safety console | TBD | Not started | Map to PDF page 139; verify actual PDF page before implementation. |
| 135 | Public · Clario Mind | TBD | Not started | Map to PDF page 140; verify actual PDF page before implementation. |

## Implementation batches

1. **Foundation and inventory:** route map, shared layout/components, accessible navigation, design tokens, responsive baseline, build/test workflow.
2. **Identity and account:** sign-up/login, verification/recovery, onboarding, profile setup, privacy preferences.
3. **Decision core:** categories, decision studio, recommendation results, saved decisions/history, goals and notifications.
4. **Plans and admin:** pricing, upgrade/payment flow, renewals/refunds, admin auth, approvals, user/plan/price management, audit trail.
5. **Public content and localization:** about/help/contact/legal/articles/forum and all language variants, including RTL Arabic.
6. **Social profiles:** customized profiles, posts, stories, followers, per-profile/post/story privacy, moderation and safe media storage.
7. **Rewards and travel:** referrals, paid-renewal loyalty, qualifying-day streaks, Tour & Travel.
8. **Clario Mind:** age-specific experiences, consent, private/saved sessions, safety/crisis pathways, volunteer/admin workflows.
9. **Release:** automated tests, staging validation, owner approval, production deployment and rollback rehearsal.

## Current baseline

The existing website is a static HTML/CSS/JavaScript app under `public/`, deployed to GitHub Pages on pushes to `main`. The current schema has core tables for profiles, decisions, usage, payments, prices, and audit logs. It is not yet evidence that all designed screens or newly requested features are implemented.


## Implementation progress update (2026-10-24)

- **Deep Think UI integration — in progress, not release-ready:** added a human-only Deep Think entry point to the existing decision studio and a dedicated board module at `public/deep-think.js`.
- **Deep Think database migration — drafted, not applied:** `supabase/migrations/202610240001_deep_think.sql` defines case submission and admin/owner review functions. Column-level read permissions exclude internal reviewer notes.
- **Not yet verified:** browser behavior, SQL execution on staging, authorization tests, and end-to-end user/admin flows.
- **Not deployed:** production branch `main` and the live GitHub Pages website have not been changed by this work.
- Social Studio has partial implementation on `#social` (see screen 19): text posts, image attachments for posts and stories, follow requests, reactions/comments, blocks/mutes/reports, outgoing follow management, and owner moderation UI are present in code; CI and real-browser verification remain outstanding.
- Profile Studio has editable display name, username, bio, interests, visibility preference, and private avatar/cover upload/removal UI. Migration `202610240006_private_profile_media.sql` defines a private bucket with owner-scoped policies; it has not been validated against a real Supabase staging project. Migration `202610240007_social_media.sql` adds a private media bucket and audience-aware storage policies for post/story image attachments; apply and runtime verification remain outstanding.
- **Tour & Travel — implemented in development, verification pending:** `public/travel-studio.js` provides private trip drafts with origin/destination, dates, solo/duo/group size, budget/currency, interests, accessibility notes, itinerary notes, archive/delete, and owner-only row-level access via migration `supabase/migrations/202610240008_travel_planner.sql`. It does not claim live prices, transport availability, bookings, or visa requirements. CI checks syntax and wiring; runtime/staging verification remains outstanding.
- **Referrals & Loyalty — implemented in development, verification pending:** `public/rewards-studio.js` provides a user referral code, referral-code application, referral status and reward history. Migration `supabase/migrations/202610240009_referrals_loyalty.sql` only records referral credits and loyalty points when a payment transitions to approved; referral credit is recorded for both parties. Reward amounts default to zero until the owner configures a policy. CI syntax/wiring checks added; database integration and staging verification remain outstanding.
- **Streak Rewards — implemented in development, verification pending:** `public/streak-studio.js` displays current/best streak, today's completed-decision count, and milestone history. Migration `supabase/migrations/202610240010_streak_rewards.sql` counts saved decisions by `Asia/Dhaka` date, qualifies days at five or more, and records the 60-day / repeating 365-day milestone crossings idempotently. Migration `supabase/migrations/202610240011_streak_entitlements.sql` now adds expiring plan grants, effective-plan resolution that preserves stronger base plans, and server-side decision-limit enforcement using the effective plan. The dashboard invokes reward delivery before refreshing. These changes are not yet validated against a staging database; CI results remain unconfirmed.
- **Clario Mind — initial adult check-in implementation added, verification pending:** `public/mind-studio.js` provides mood/needs check-ins, language selection, client-only temporary reflections or saved sessions, saved-history listing and deletion, and an explicit non-therapy/non-emergency disclaimer. Migration `supabase/migrations/202610240012_clario_mind.sql` adds RLS and server-side validation. Sessions for users under 18 are deliberately blocked until guardian-consent and age-specific safeguards are implemented. Crisis-resource localization, formal retention/privacy review, database integration tests, and staging validation remain outstanding.
