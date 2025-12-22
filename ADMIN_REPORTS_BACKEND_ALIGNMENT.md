# Admin Mobile Reporting – Backend Alignment

_Last update: 2025-12-21_

## 1. Scope & Objectives
- Provide the mobile admin dashboard with consistent KPI blocks for Users, Clubs, Events, and Alerts.
- Define the backend data sources, refresh cadence, and contracts required to power every widget.
- Lock SLA targets (latency, freshness, availability) so frontend can surface "last synced" states and fallbacks.
- Establish ownership, monitoring, and delivery checkpoints shared across product, backend, and mobile teams.

## 2. Dashboard Modules & Data Inventory

### 2.1 Overview KPIs (header carousel)
| KPI | Purpose | Source of Truth | Freshness Target | Owner/Notes |
| --- | --- | --- | --- | --- |
| Live Events Count | Show number of events currently in progress | `events` table (status = live) or `events-service` cache | ≤30s delay | Backend Events squad; include campus filters |
| Pending Approvals | Track workload + SLA risk | `approvals` table (status pending) | ≤1 min | Admin Ops service; include SLA breach flag |
| Active Users (DAU/WAU) | Gauge traction | `user_activity` aggregated view | ≤5 min | Identity squad; needs faculty filter |
| Revenue (VND) | Display gross ticket revenue | `payments` service aggregated per range | ≤15 min | Finance service; include currency metadata |
| Complaints Open | Monitor outstanding issues | `support_tickets` (type=complaint) | ≤2 min | Support squad; include severity bucket |

### 2.2 User Insights Section
| Metric | Description | Data Source | Needed Fields | Refresh |
| --- | --- | --- | --- | --- |
| New Registrations | Count of newly verified accounts | `users` table w/ `created_at` | id, name, faculty, created_at | Near real-time |
| Daily/Weekly Active | Unique users with activity events | `user_activity` fact table | user_id, event_type, timestamp | 5 min batch |
| Conversion Rate | Registrations → first event participation | Join `users` + `event_participants` | aggregated counts per range | Hourly |
| Inactive Users | Users w/ no activity in X days | Derived view | inactivity_days, contact info | Hourly |
| Top Faculties | Faculties with highest engagement | Aggregated view | faculty_id, counts, delta | 15 min |

### 2.3 Club Insights Section
| Metric | Description | Source | Fields | Refresh |
| --- | --- | --- | --- | --- |
| Active Clubs | Clubs with ≥1 event in range | `clubs` + `events` join | club_id, status | 5 min |
| Dormant Clubs | No events in last 60 days | Derived view | club_id, last_event_at | Daily |
| Membership Growth | Net member change per club | `club_members` history | join_date, leave_date | Hourly |
| Revenue Contribution | Ticket revenue per club | `payments` + `events` | revenue, payout_status | 15 min |
| Compliance Flags | Violations & warnings | `compliance_cases` | case_type, severity, resolved | Near real-time |

### 2.4 Event Insights Section
| Metric | Description | Source | Fields | Refresh |
| --- | --- | --- | --- | --- |
| Approval SLA | Avg time from submit → approval | `approvals` history | submitted_at, approved_at | Hourly |
| Cancellation Rate | % cancelled vs total | `events` statuses | event_id, status | 5 min |
| Capacity Fill | Seats taken vs capacity | `event_participants` + `events.capacity` | counts, capacity | Near real-time |
| Satisfaction Score | Avg rating per event | `feedback` table | score, comment_count | 30 min |
| Event Timeline | Ordered list of up-next events | `events` | start/end, organizer, risk_score | Near real-time |

### 2.5 Alerts & Tasks Section
| Alert Type | Trigger | Source | Action Data |
| --- | --- | --- | --- |
| Risky Events | risk_score ≥ threshold or complaint spike | `events_risk_view` | event_id, reason, SLA minutes |
| Complaints Aging | Complaint open > 24h | `support_tickets` | ticket_id, contact |
| Approvals Aging | Pending approval > 48h | `approvals` | approval_id, submitted_at |
| Export Jobs | Background exports ready/failed | `report_exports` | job_id, status, download_url |

## 3. API Contract Summary & Ownership
| Endpoint | Method | Purpose / Key Payload | Filters | Owner | ETA |
| --- | --- | --- | --- | --- | --- |
| `/api/admin/reports/overview` | GET | Top carousel metrics + lastUpdated | `range`, `facultyId`, `eventType` | Events squad | 2026-01-05 |
| `/api/admin/reports/users/metrics` | GET | Aggregated user KPIs + sparklines | `range`, `facultyId`, `departmentId` | Identity squad | 2026-01-05 |
| `/api/admin/reports/users/list` | GET | Paginated user table w/ action flags | `status`, `range`, `page` | Identity squad | 2026-01-08 |
| `/api/admin/reports/clubs/metrics` | GET | Club summaries, comparisons | `range`, `cluster`, `clubIds[]` | Communities squad | 2026-01-10 |
| `/api/admin/reports/clubs/list` | GET | Club list w/ health flags | `sort`, `page`, `status` | Communities squad | 2026-01-10 |
| `/api/admin/reports/events/metrics` | GET | SLA, cancellation, capacity | `range`, `status`, `facultyId` | Events squad | 2026-01-05 |
| `/api/admin/reports/events/timeline` | GET | Chronological events feed | `range`, `status` | Events squad | 2026-01-03 |
| `/api/admin/reports/alerts` | GET | Aggregated alert cards | `severity`, `type` | Admin Ops squad | 2026-01-03 |
| `/api/admin/reports/export` | POST | Start export job (csv/pdf) | body: `sections[]`, `range`, filters | Reporting squad | 2026-01-12 |
| `/api/admin/reports/export/{jobId}` | GET | Poll job status + download | `jobId` | Reporting squad | 2026-01-12 |
| `/api/admin/reports/config` | GET/PUT | Persist dashboard layout/filter prefs | auth user scope | Platform squad | 2026-01-15 |
| `/api/admin/reports/audit` | GET | Admin action log | `range`, `actorId`, `actionType` | Compliance squad | 2026-01-15 |

_All endpoints must honor admin scopes (global vs faculty-level) from JWT claims; backend enforces row-level filtering before response._

## 4. SLA & Performance Targets
| Dimension | Target | Notes |
| --- | --- | --- |
| Data Freshness | Overview ≤30s, Users/Clubs ≤5 min, Finance ≤15 min | Frontend shows `lastUpdated` timestamp per section |
| API Latency (p95) | ≤800 ms for metrics, ≤1.5 s for list endpoints | Includes filter + pagination overhead |
| Availability | 99.5% monthly for read APIs | Use blue/green deploy + canary |
| Consistency | Event + user counts should not differ >1% vs source-of-truth nightly batch | Automated diff job raises alert |
| Export Job Completion | 95% within 2 min for <10k rows | Async worker autoscaling |

## 5. Data Refresh & Sync Strategy
- Use change-data-capture streams from `events`, `approvals`, `payments` into a reporting store (e.g., BigQuery/Snowflake) powering aggregated views consumed by APIs.
- Cache overview metrics in Redis for 30s TTL; bust cache when new CDC batch arrives to avoid stale numbers.
- Batch jobs (hourly/daily) emit `cacheVersion` so frontend can call with `If-None-Match` to reduce payload.
- Provide `lastUpdated` + `source` metadata in every response; mobile shows skeletons until data arrives or displays cached numbers with "Synced 5m ago" label.
- When a source feed lags beyond SLA, backend sets `degraded=true` flag so frontend shows warning banner.

## 6. Monitoring & Alerting
- Instrument each endpoint with tracing (OpenTelemetry) and push metrics (latency, error rate, cache hit) to Grafana dashboards.
- Create automated data-quality checks (duplicate counts, negative deltas, zero values) running hourly; failures raise PagerDuty alert to owning squad.
- Log every export job transition; retry failures up to 3 times before surfacing `status=failed` and notification to user.
- Emit webhook/event `report_data.updated` so mobile can refresh on push rather than polling.

## 7. Delivery & Collaboration Plan
| Milestone | Date | Owner | Notes |
| --- | --- | --- | --- |
| Contract review & mock payloads | 2025-12-23 | Product + Backend leads | Validate schema, decide on optional fields |
| Staging endpoints ready | 2026-01-05 | Respective squads | Provide Postman collection + sample data |
| Data QA vs manual reports | 2026-01-08 | Analytics + QA | Compare numbers over 3 date ranges |
| Mobile integration freeze | 2026-01-15 | Mobile team | Requires stable responses |
| Production launch & monitoring | 2026-01-22 | All squads | 24h hyper-care, alert routing tested |

## 8. Immediate Action Items
1. Backend squads confirm data ownership table above and flag missing data by **2025-12-22**.
2. Provide sample JSON payloads for every endpoint and share via API docs repo.
3. Set up shared dashboard tracking the SLA metrics (freshness, latency) before staging release.
4. Schedule twice-weekly sync (Tue/Fri) to unblock schema or data gaps; notes stored in this repo.

This document will evolve as we learn more about data sources; update the tables whenever ownership, SLA, or timelines change.
