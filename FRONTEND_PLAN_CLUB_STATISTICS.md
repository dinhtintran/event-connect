# Frontend Implementation Plan – Club Statistics

## 1. Foundation & Data Layer
- **Re-sync models**: Regenerate `Event` model fields (`averageRating`, `ratingCount`, `attendedCount`, `posterUrl`) from backend schema once available.
- **Introduce `ClubStatisticsSummary` domain model**: responsible for parsing API response, computing derived metrics (monthly series, change %, highlight fallbacks).
- **Repository wiring**: `ClubAdminRepository.getClubStatistics(clubId)` calls the new backend endpoint, handles API errors, and wraps results into the domain model.

## 2. Screen State Management
- **Club ID flow**: ensure `_loadClubId` persists the resolved ID, then trigger `_fetchStatistics(clubId)` exactly once per session or on pull-to-refresh.
- **Async states**: track `loading`, `errorMessage`, `hasRealData`. Provide retry callback to re-run `_fetchStatistics`.
- **Empty state**: when summary is empty, show guidance card instead of stale metrics.

## 3. UI Integration
- **Metrics header**: bind totals/rates/deltas from `ClubStatisticsSummary` instead of hardcoded numbers.
- **Charts**: feed `monthlyAttendance` into bar/line chart widget; guard against <6 data points.
- **Distribution cards**: map `academicYearDistribution` to progress indicators, fallback to placeholders if zeroed.
- **Feedback & highlights**: render lists directly from API data, hide section when arrays empty.
- **Colors & theming**: replace deprecated `withOpacity` with `withValues(alpha: …)`.

## 4. Resilience & UX polish
- **Error banner** with action button (`Try again`).
- **Pull-to-refresh** integration to re-fetch stats.
- **Skeleton/placeholder** components while loading.
- **Accessibility**: ensure cards have semantic labels and percentage text.

## 5. QA & Tooling
- Run `flutter analyze` and fix lint warnings (unused imports, unused fields).
- Add widget tests for state transitions (loading → success, error → retry, empty data).
- Capture golden screenshots for success and empty states.
- Document integration steps in `ADMIN_UI_README.md` once feature stabilizes.

## 6. Dependencies & Risks
- Blocked until backend provides contract and staging endpoint; in meantime create mock provider matching schema for local testing.
- Need sample accounts for multiple clubs to verify `_clubId` mapping.
- Monitor performance of chart rendering with large lists; consider caching results in memory for session.
