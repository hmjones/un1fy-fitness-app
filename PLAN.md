# UN1FY

Mindbody-connected fitness companion app with stats, leaderboards, badges, challenges, and profile.

## Notes

- Dev skip-onboarding flag remains in `UN1FYApp.swift` (`DEV_SKIP_ONBOARDING = true`)
- Onboarding flow: Welcome → Mindbody → Notifications → Name → Celebration
- Calorie tracking feature and its onboarding metrics (gender, height, weight, age, activity level) were removed
- Leaderboards ("Ranks" tab) read live from the shared Supabase `leaderboard_snapshot` table (project `gzxphxqjjdickalcilrq`) via REST using the publishable anon key. Boards: This Month, All Time, Streaks, Milestones. Rebuilt nightly by the Vercel cron; the app pulls on appear / pull-to-refresh.
- Home/Stats personal numbers (All Time total, This Month, Current Streak) are merged from the same `leaderboard_snapshot` data, matched by Mindbody `client_id` (if the auth payload returns it) or by display name ("First L."). Only overrides the seed when a matching row exists — so it covers members ranked in a board's top 25. Triggered after connect/sync (`MemberStore.refreshPersonalStatsFromLeaderboard()`).
- The per-member `visits` table is now readable by the anon key (SELECT policy added, same pattern as `leaderboard_snapshot`). On connect/sync, `MemberStore.refreshVisits()` resolves the member's `client_id` (from the auth payload, or looked up from `leaderboard_snapshot` by display name) and pulls their full visit history via `SupabaseVisitsService`. This drives the real attendance heat map, class-type breakdown, and the derived counts: total classes, This Week, This/Last Month, Best Month, and current/longest streaks (consecutive attended days). The `auth-mindbody` edge functions still only return name, so visits are the canonical personal-data source.
