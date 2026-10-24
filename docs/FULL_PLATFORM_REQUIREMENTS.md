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

## Social profiles and community

### Profile setup and customization
- Users create and customize profiles inspired by familiar social platforms, while preserving Clario's decision-support purpose.
- Profile fields may include profile photo, cover photo, display name, unique username, biography, interests, and optional location / personal or professional details.
- Support profile presentation customization and photo/video galleries; allow users to edit or delete their own profile details and media.
- Profile media is separate from decision-related uploads and does not consume decision-upload quotas unless the owner explicitly changes this rule.

### Privacy and audience controls
- **Required onboarding choice: users choose their profile privacy during setup**; do not force public or private as a universal default.
- Available profile visibility options: public, private, and followers-only, with clear explanations of what each means.
- Every post and every story has its own audience selector, so its visibility can differ from the overall profile setting.
- Enforce the most restrictive applicable privacy rule on the server; a per-post audience choice must never accidentally expose content beyond permissions granted by the profile owner.
- Provide account privacy settings, follower/following management, follow requests where applicable, and controls to remove followers.
- Provide block, mute, report, content moderation, abuse handling, and account/content deletion workflows.
- Private media must use authorized access / signed URLs and storage policies. Validate file type, size, content, and malware risk.

### Posts and stories
- Support photo and video posts with captions, hashtags, optional tags, reactions/likes, comments, shares, and saves, subject to privacy settings and moderation.
- Users can edit or delete their own posts and control the audience for each post.
- Support temporary photo/video stories with audience controls, viewer list and reactions.
- Default story lifetime: 24 hours, with expiration enforced server-side. Expired stories may be retained only where necessary for security, moderation, or legal obligations under a documented retention policy.
- Links, music, stickers, and other enhanced story tools are subject to safety, licensing, and platform capability checks; do not promise unavailable integrations.
- Notifications and messaging are separate scope items and must respect blocks, privacy settings, and user safety controls before being enabled.

## Tour & Travel (Pro and above)
- Solo, duo, and group trip modes.
- Ask travel wishes, origin, destination or destination preferences, dates, group size, budget, mobility/accessibility needs, and interests.
- Recommend practical routes, transport options, estimated durations/costs when reliable provider data is available.
- Include historical visits, iconic must-see places, and day-by-day itineraries.
- Clearly label estimates, show data freshness, and never invent live route, opening-hour, or price data.
- Respect location privacy; request only the location needed for the trip.


## Deep Think — human-only decision workflow (all plans)

- Deep Think is available to every account tier, including Free; it must not be paywalled by subscription.
- When creating a decision, the user can explicitly choose either the normal Clario workflow or **Deep Think**. Explain before submission that Deep Think is reviewed by a human administrator/owner and does not use AI for analysis or the final decision.
- Deep Think opens a dedicated **Deep Think Board** for the decision. The user can provide the full context they consider relevant to their life, including goals, constraints, background, relationships, finances, education/career, lifestyle, options, risks, priorities, supporting notes and attachments. Use clear sections and allow the user to skip irrelevant sections; do not require unnecessary sensitive details.
- No AI model or AI-generated summary, ranking, recommendation, classification, inference, or decision may be used anywhere in the Deep Think analysis/review path. Do not send Deep Think board content to AI APIs or use it to generate AI embeddings.
- Submission creates a pending human-review case. Only authorized **admin** and **owner** roles can access the board and submit the official decision. Other users, ordinary support roles, and public/community features must not expose it. Enforce this with server-side authorization and database/storage policies, not just hidden UI.
- Admin/owner reviews the original user-provided information and may ask the user for clarification; record questions, answers, reviewer identity, timestamps, status changes, and the final decision in an auditable case history.
- Suggested statuses: Draft, Submitted, In Review, Needs Information, Decision Ready, Delivered, Closed. Users can view their own case status and the delivered decision, but cannot view internal admin-only notes.
- Make access scope, human-only handling, expected review status, and any response-time estimate clear before submission. Do not promise a turnaround time until an operational service level is approved.
- Treat board content and attachments as highly private. Apply least-privilege access, secure upload validation, encryption in transit/at rest where supported, access audit logs, retention/deletion rules, and account deletion handling. Never use board content for model training.
- Preserve normal AI-assisted decisions as a separate workflow; selecting Deep Think must explicitly bypass AI processing. Admin/owner must not use AI tools to analyze the case as part of the Clario Deep Think workflow.
- Acceptance tests: Free and paid users can select Deep Think; no AI/API processing occurs; unauthorized roles cannot read or decide cases; admin/owner can review and deliver a decision; user sees only their own board and public-facing case history; internal notes remain private; access and decision events are audited.

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
