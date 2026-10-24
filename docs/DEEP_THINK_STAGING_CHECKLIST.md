# Deep Think staging validation checklist

This feature handles private life-context submissions. Do not release it based on a successful frontend build alone.

## Current state
- [x] Dedicated Deep Think board module added to `public/deep-think.js`.
- [x] Decision Studio entry button wired in `public/index.html`.
- [x] Database migration drafted at `supabase/migrations/202610240001_deep_think.sql`.
- [ ] Migration applied to a separate staging Supabase project.
- [ ] Browser tests completed for signed-in user, signed-out user, admin, owner and unauthorized account.
- [ ] Confirmed no Deep Think board content is sent to an AI API, logging service, analytics event, or embedding pipeline.
- [ ] Confirmed the user's own case list cannot read another user's cases.
- [ ] Confirmed non-admin users cannot read the review queue or change a case.
- [ ] Confirmed internal reviewer notes are not returned to ordinary client queries.
- [ ] Confirmed delivered decisions are visible only to the case owner and authorized reviewers.
- [ ] Confirmed audit events are written on submission and every review/status update.
- [ ] Confirmed accessibility and responsive layout on mobile and desktop.
- [ ] Owner approved staging results before production release.

## Staging procedure
1. Create/use a separate Supabase staging project. Do not apply this migration to production as a test.
2. Review the migration against the actual staging schema, especially `profiles.id` and the role values (`admin`, `owner`).
3. Apply `supabase/migrations/202610240001_deep_think.sql` to staging.
4. Deploy the feature branch to an isolated preview environment; do not merge to `main` for this test.
5. Create separate test accounts for a normal user, an admin, an owner and an unrelated user.
6. Run every security test above, including attempts to call RPCs directly with unauthorized accounts.
7. If any access test fails, stop and fix the migration before considering production.
8. Only after the user reviews and approves staging should the production migration and frontend deployment be scheduled.

## Important
GitHub Pages publishes static frontend files only. The SQL migration is not automatically applied by the Pages deployment workflow. A missing migration should produce a controlled unavailable message, not be treated as a successful launch.
