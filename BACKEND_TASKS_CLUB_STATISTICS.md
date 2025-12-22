# Backend Tasks – Club Statistics API

## 🎯 Objectives
- Expose **real-time statistics** per club so the Club Statistics screen can stop relying on hardcoded mock data.
- Provide **consistent aggregates** (totals, rates, deltas, highlight assets, feedback samples) for 30–90 recent days.
- Deliver **predictable error handling** so frontend can display retry/empty states.

---

## 📡 Required Endpoints

### 1. `GET /api/clubs/{club_id}/statistics/`
Single endpoint returning all metrics needed by the dashboard.

**Query params (optional):**
- `range_days` (default `90`) – window size for aggregations.
- `limit_feedback` (default `3`) – max feedback summaries to return.
- `limit_highlights` (default `6`).

**Response schema:**
```jsonc
{
  "club_id": "string",
  "generated_at": "2025-12-21T09:30:00Z",
  "overview": {
    "total_participants": 1200,
    "attendance_rate": 85.4,
    "completed_events": 18,
    "satisfaction_level": 4.6
  },
  "changes": {
    "participants_pct": 12.5,
    "attendance_pct": -3.1,
    "events_delta": 1,
    "satisfaction_pct": 0.2
  },
  "series": {
    "monthly_attendance": [250, 310, 450, 380, 500, 620],
    "academic_year_distribution": {
      "freshman": 35,
      "sophomore": 28,
      "junior": 22,
      "senior": 15
    }
  },
  "feedbacks": [
    {
      "title": "Workshop Python",
      "rating": 4.9,
      "comment": "Rất chuyên nghiệp",
      "avatar_url": "https://.../avatar.png"
    }
  ],
  "highlights": [
    {
      "poster_url": "https://.../poster.jpg",
      "event_id": "evt_123",
      "title": "Dev Summit"
    }
  ]
}
```

### 2. `GET /api/clubs/{club_id}/statistics/raw-events/` (optional but recommended)
Returns the raw event list (with ratings, attendance, poster URL) used for debugging or advanced charts. This can share the same serializer as existing `getClubEvents` but **must include** `average_rating`, `rating_count`, `attended_count` and `poster_url`.

---

## 🧮 Calculation Rules

| Metric | Formula | Notes |
| --- | --- | --- |
| `total_participants` | Σ `max(total_participants, registration_count)` over window | Guard negatives. |
| `attendance_rate` | `(Σ attended / Σ registrations) * 100` | Return `0` when denominator `0`. Round to 1 decimal. |
| `completed_events` | Count events with status `completed` OR (`approved` and `end_at < now`). |
| `satisfaction_level` | Average of `average_rating > 0`. Round to 1 decimal. |
| `participants_pct` | Percent change of last month vs previous month derived from monthly series. Cap at `±100`. |
| `attendance_pct` | Compare average attendance of last 3 events vs previous 3. |
| `events_delta` | `events(last 30d) - events(30–60d)`. |
| `satisfaction_pct` | Percent change between current average rating and previous half of dataset. |
| `monthly_attendance` | Last 6 months of registration counts grouped by month. Empty months must yield `0`. |
| `academic_year_distribution` | Map event categories or metadata to academic buckets; fall back to equal distribution if unknown. |

---

## 🧱 Data Requirements
- `Event` model must expose: `registration_count`, `attended_count`, `total_participants`, `average_rating`, `rating_count`, `poster_url`, `category`, `start_at`, `end_at`, `status`.
- Feedback samples should include **title + comment**. If user feedback table exists, choose latest comments; otherwise derive from top-rated events (see placeholder logic above).
- Highlights prefer uploaded poster URLs; if missing, return fallback asset reference.

---

## ⚙️ Validation & Error Handling
- Return `404` when club_id not found.
- Return `200` with `is_empty: true` flag (or zeroed metrics) when club has no events.
- Provide machine-readable `error_code` for backend outages (ex: `statistics_generation_failed`).
- Response must be cacheable for 5–10 minutes; include `Cache-Control` hints if possible.

---

## 🔐 Security & Performance
- Require authenticated club admins or higher roles; ensure a club admin can only access their own club statistics.
- Use DB-level aggregation (Django ORM `annotate`, Postgres window functions, or stored procedures) instead of fetching everything to Python.
- Add indexes on `events.clb_id`, `start_at`, `status` to keep windowed queries fast.
- Consider precomputing nightly materialized view if dataset grows >100k events.

---

## ✅ Deliverables Checklist
- [ ] Endpoint implemented with serializer + view + URL route.
- [ ] Unit tests covering empty dataset, partial data, full dataset.
- [ ] Sample fixtures for QA (club with 6+ months of events).
- [ ] API documentation (Swagger or DRF schema) updated.
- [ ] Feature toggle or versioning plan if existing clients might break.

---

## ⏱ Proposed Timeline
| Day | Task |
| --- | --- |
| 0–1 | Finalize schema, add migrations if new tables/fields required. |
| 2–3 | Implement endpoint + serializer + db aggregations. |
| 4 | Write tests, QA with sample data, optimize queries. |
| 5 | Provide test endpoint to frontend & iterate on contract feedback. |

> Ping frontend team when mock JSON is ready so we can unblock integration even before full prod deployment.
