# Clario Full Platform Recovery — Product Requirements

Status: implementation scope / not yet deployed
Target: preserve `main` and the current GitHub Pages site while building on `feature/full-platform-recovery`.

## Non-negotiable delivery rules
- Preserve the existing live site and all existing features.
- Reconstruct and implement the user's 135 designed screens; do not replace them with a reduced one-page approximation.
- Use the original designs as the source of truth. A screen-by-screen inventory and design-to-route mapping is required before claiming all 135 screens are implemented.
- Keep secrets out of frontend code. Enforce permissions, plans, quotas, rewards, payments, and file access on the server.
- No production migration or deployment until staged tests pass and the owner approves release.

## Existing platform and deployment
- Repository: Saifshowmik/Clario; default branch: main.
- Current frontend: static HTML/CSS/JS under public/ and deployed through GitHub Pages.
- Existing database source: schema.sql; Supabase is configured in public/config.js.
- Use a separate staging backend/project for migrations and integration tests. Never assume the current Supabase project is safe for destructive changes.

## Subscription prices (preserve exactly)
| Plan | Weekly | Monthly | Yearly |
|---|---:|---:|---:|
| Free | ৳0 | ৳0 | ৳0 |
| Pro | ৳29 | ৳99 | ৳1,099 |
| Premium | ৳59 | ৳199 | ৳1,999 |
| Extra Premium | ৳299 | ৳999 | ৳9,999 |

Prices are product requirements. Payment settlement, renewals, refunds, and plan entitlements require server-side verification.

## Decision quotas and uploads
- Free: 5 completed decisions per Bangladesh calendar day.
- Pro: 15 completed decisions per Bangladesh calendar day.
- Premium: 25 completed decisions per Bangladesh calendar day and up to 5 decision pictures per day.
- Extra Premium: unlimited decisions subject to documented fair-use controls; up to 25 decision pictures and 5 additional file attachments per day.
- Extra Premium supported attachment types should include video, PDF, DOC/DOCX, PPT/PPTX, CSV and other explicitly allowlisted formats.
- Profile photos/videos are a separate media allowance and do not consume decision-upload quotas unless the owner later changes this rule.
- All counters must be atomic, server-enforced, abuse-resistant, and reset according to Asia/Dhaka calendar days.

## Consistency rewards
- A qualifying day requires at least 5 completed, valid decisions on that day. Login alone does not qualify.
- 60 consecutive qualifying days: grant 7 days of Pro entitlement.
- 365 consecutive qualifying days: grant 1 day of Extra Premium entitlement.
- The 365-day reward recurs at each subsequent 365-day milestone in a continuing streak (e.g. day 730, 1,095).
- Missing a calendar day resets the active streak to zero.
- Display streak, progress to next reward, reward history, and granted entitlement in the dashboard.
- Rewards are granted exactly once per milestone by server-side transactional logic. Prevent duplicates and do not count failed, deleted-as-invalid, or fraudulent decisions.

## Paid-renewal loyalty rewards
- Earn only from successfully verified paid renewals / continued paid membership; free usage and ordinary activity do not earn loyalty points.
- Preserve current prices. Calculate rewards from eligible net subscription payment after discounts/refunds/chargebacks; exclude taxes and payment-processing amounts where applicable.
- Reward rate, point conversion, expiry, caps, and redemption rules remain pending owner approval; do not invent/finalize economics in code.
- Maintain an immutable ledger; reverse or adjust rewards for refunds and chargebacks.

## Referrals and discounts
- Referral program may be available to users on any plan.
- Reward inviter and invitee only after a qualifying verified paid subscription; eligibility windows, discount rates, caps, and expiry require owner approval.
- Prevent self-referrals, duplicate accounts, repeated claims, referral loops, and client-side reward tampering.
- Admin configuration and audit history are required.

## Social profile
- Profile picture, cover image, biography, interests, photo/video gallery.
- Privacy settings; explicit audience visibility; edit/delete; report/block; consent and moderation.
- Private media must use authorized access / signed URLs and storage policies. Validate file type, size, content, and malware risk.

## Tour & Travel (Pro and above)
- Solo, duo, and group trip modes.
- Ask travel wishes, origin, destination or destination preferences, dates, group size, budget, mobility/accessibility needs, and interests.
- Recommend practical routes, transport options, estimated durations/costs when reliable provider data is available.
- Include historical visits, iconic must-see places, and day-by-day itineraries.
- Clearly label estimates, show data freshness, and never invent live route, opening-hour, or price data.
- Respect location privacy; request only the location needed for the trip.

## Existing Clario modules to preserve
- Public marketing pages, authentication, customer dashboard, Decision Studio, result explanations, shopping/technology decisions, life-partner/match profiles, AI-assisted analysis with admin final approval, admin console, user/plan management, payment review, prices, audit logs, multiple languages, and Clario Mind.
- Clario Mind: age-specific experiences for all age groups, multiple languages, temporary private sessions plus optional saved sessions, appropriate safeguards, and legally required guardian consent. Implement privacy and safety controls before launch.

## Production requirements
- Secure authentication and role-based access control; MFA for admins recommended.
- Server-side payment verification, subscription expiration and renewal lifecycle, idempotent webhooks, refunds/chargebacks, and audit logging.
- Database row-level security and storage policies; rate limits; upload validation/scanning; backups and recovery; privacy controls and account deletion.
- Accessibility, responsive mobile design, localization, observability, error handling, automated tests, and documented recovery/rollback.

## Required acceptance checklist
- A 135-row screen inventory with design reference, route, status, dependencies, and acceptance criteria.
- Every existing feature mapped to an implemented route and tested workflow.
- Automated tests for plan limits, Dhaka day-boundaries, streak reset, 60/365-day reward idempotency, referral abuse, refunds, file quotas, privacy, and role permissions.
- Staging validation and explicit owner approval before production deployment.
