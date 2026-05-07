# GotTheKeys JSON API — v1 Spec

**Status:** Implemented v1 buyer/renter API
**Owner:** Steven
**Last updated:** 2026-04-26
**Target Rails version:** 8.1.3

## 1. Goals & Non-Goals

### Goals
- Expose the buyer/renter side of GotTheKeys as a JSON HTTP API consumable by an iOS app and, later, a web SPA, an Android app, or third-party clients.
- Reuse the existing domain models, validations, and business rules without duplicating logic into a parallel API stack.
- Keep the API surface narrow and stable: ship only what the iOS app needs in v1, version cleanly, and leave room to grow.
- Mirror the security posture of the web app — Rack::Attack rate limits, Devise lockouts, account lifecycle controls, and email-based audit trails apply equally to API traffic.

### Non-Goals (v1)
- No seller/owner endpoints (creating/editing properties, uploading photos, managing viewing times). Sellers continue to use the web app.
- No admin endpoints (triage, decisions, demo data, booking config). Admins continue to use the web app, including 2FA.
- No real-time/push channels. Notifications stay email-only for now; APNs is a v2 concern.
- No GraphQL, no JSON:API envelope, no OAuth/third-party app authorization.
- No public anonymous "submit an enquiry without an account" path beyond what the web already supports — see §5.7 for the v1 decision.

## 2. Top-Level Decisions

| Decision | Choice |
|---|---|
| Auth | JWT bearer tokens via `devise-jwt`, with rotating refresh tokens |
| Scope | Buyer/renter only |
| Versioning | URL path: `/api/v1/...` |
| Response format | Plain REST JSON, per-endpoint shapes |
| Serialization | `jsonapi-serializer` (Netflix) used as a serializer only — *not* the JSON:API envelope |
| Content type | `application/json; charset=utf-8` request and response |
| Time format | RFC 3339 / ISO 8601 in UTC, e.g. `2026-04-26T14:30:00Z` |
| Money | Integer pence (existing `asking_price` and `amount` fields are already integers) |
| IDs | Integer primary keys exposed as numbers; `public_reference` strings used for human-shareable resources (appointments, offers, rental applications, enquiries) |
| Locale | `Accept-Language` header drives I18n; falls back to user's stored `language` |
| Pagination | Page-based, mirroring Kaminari: `?page=`, `?per_page=` (max 50, default 12 to match web) |

## 3. URL & Routing Layout

All routes mounted under `/api/v1/`. Implemented under `app/controllers/api/v1/`, inheriting from `Api::V1::BaseController < ActionController::API`. Shared concerns live under `app/controllers/concerns/api/v1/`.

```
namespace :api do
  namespace :v1 do
    # Auth
    post   "auth/register"          # create user account
    post   "auth/login"             # exchange credentials for JWT
    post   "auth/refresh"           # rotate refresh token -> new access token
    delete "auth/logout"            # revoke current refresh token
    post   "auth/password"          # request password reset email
    patch  "auth/password"          # complete password reset with token
    # Profile
    get    "me"                     # current user
    patch  "me"                     # update profile
    delete "me"                     # account deletion (soft-delete or schedule)

    # Catalogue (public, no auth required for read)
    get    "properties"             # search/filter listings
    get    "properties/:id"         # property detail
    get    "properties/:id/availability"  # next bookable slots
    get    "properties/:property_id/documents/:id/download" # public document stream

    # Saved properties / searches (auth required)
    get    "saved_properties"
    post   "saved_properties"       # body: { property_id }
    delete "saved_properties/:property_id"

    get    "saved_searches"
    post   "saved_searches"
    patch  "saved_searches/:id"
    delete "saved_searches/:id"

    # Enquiries (auth required in v1; see §5.7)
    post   "properties/:property_id/enquiries"

    # Appointments (viewing bookings)
    post   "properties/:property_id/appointments"
    get    "appointments"           # current user's appointments
    get    "appointments/:public_reference"
    patch  "appointments/:public_reference/reschedule"
    patch  "appointments/:public_reference/cancel"

    # Offers (sale properties only)
    post   "properties/:property_id/offers"
    get    "offers"                 # current user's offers
    get    "offers/:public_reference"
    patch  "offers/:public_reference/withdraw"

    # Rental applications (rental properties only)
    post   "properties/:property_id/rental_applications"
    get    "rental_applications"
    get    "rental_applications/:public_reference"
    patch  "rental_applications/:public_reference/withdraw"

    # Reference data (cacheable, low-churn)
    get    "reference/property_types"
    get    "reference/sale_statuses"
    get    "reference/sort_options"
    get    "reference/languages"
    get    "reference/booking_window"  # slot duration, lead time, booking window in days
  end
end
```

The existing HTML controllers stay untouched. The API controllers call into the same models and service objects (`AppointmentAvailability`, `PropertyNextAvailableSlotLookup`, etc.), so business rules live in one place.

## 4. Authentication

### 4.1 Token model

Two-token system implemented with `devise-jwt`:

- **Access token** — short-lived JWT (15 minutes). Sent on every request in `Authorization: Bearer <token>`. Stateless: claims include `sub` (user id), `jti` (unique id), `exp`, `iat`, `aud=ios|web|generic`.
- **Refresh token** — long-lived (30 days), opaque random string stored in a new `api_refresh_tokens` table. Rotated on every use; old token is revoked. Tied to a `device_id` and a friendly `device_name` so users can audit/revoke from a future settings screen.

Access-token revocation uses the same `jti` idea as `devise-jwt`'s `JTIMatcher`: `users.jti` tracks the active token id, so logout and refresh-token reuse detection invalidate outstanding access tokens for that user. Refresh tokens are stored and revoked individually.

### 4.2 New table: `api_refresh_tokens`

```ruby
create_table :api_refresh_tokens do |t|
  t.references :user, null: false, foreign_key: true, index: true
  t.string  :token_digest, null: false, index: { unique: true }  # SHA-256 of token
  t.string  :device_id,    null: false                           # client-generated UUID
  t.string  :device_name                                         # "Steven's iPhone"
  t.string  :user_agent
  t.string  :ip_address
  t.datetime :expires_at,  null: false
  t.datetime :revoked_at
  t.datetime :last_used_at
  t.timestamps
end
add_index :api_refresh_tokens, [:user_id, :device_id]
```

### 4.3 New column on `users`

```ruby
add_column :users, :jti, :string
add_index  :users, :jti, unique: true
# Backfill with SecureRandom.uuid for existing rows in the same migration.
```

### 4.4 Endpoints

#### `POST /api/v1/auth/register`

```json
// Request
{
  "email": "buyer@example.com",
  "password": "correcthorsebatterystaple",
  "first_name": "Sam",
  "last_name":  "Buyer",
  "mobile_number": "+447700900123",
  "language": "en",
  "terms_of_service": true,
  "device_id":   "5C3B...-UUID",
  "device_name": "Sam's iPhone"
}

// 201 Created
{
  "user":   { ...UserResource },
  "access_token":  "eyJhbGc...",
  "refresh_token": "rt_8f3a...",
  "expires_in":    900
}
```

The user is logged in immediately after successful registration. The current v1 routes do not expose JSON confirmation endpoints; email confirmation can be added later if the product decision changes.

#### `POST /api/v1/auth/login`

```json
// Request
{ "email": "...", "password": "...", "device_id": "...", "device_name": "..." }

// 200 OK — same shape as register
```

Failed attempts increment Devise's lock counter as on the web. Rate-limited the same way (5/5min/email, 10/5min/IP).

#### `POST /api/v1/auth/refresh`

```json
// Request
{ "refresh_token": "rt_8f3a...", "device_id": "..." }

// 200 OK
{ "access_token": "eyJ...", "refresh_token": "rt_NEW...", "expires_in": 900 }
```

Refresh rotation: presenting a refresh token issues a new access *and* new refresh token, then marks the old refresh token revoked. Reusing a revoked refresh token is a critical signal — we revoke *all* refresh tokens for that user and log an audit entry.

#### `DELETE /api/v1/auth/logout`

Revokes the current refresh token (passed in body) *and* updates `users.jti`, invalidating all outstanding access tokens.

```json
// Request body
{ "refresh_token": "rt_8f3a..." }

// 200 OK
{ "logged_out": true }
```

#### Password reset

`POST /api/v1/auth/password` always returns 202 regardless of whether the email exists (user enumeration prevention):

```json
// 202 Accepted
{ "accepted": true, "message": "If that email is registered, password reset instructions have been sent." }
```

`PATCH /api/v1/auth/password` completes the reset using the token from the email. Also unlocks a locked account as a side effect:

```json
// Request
{ "reset_password_token": "...", "password": "newpassword1", "password_confirmation": "newpassword1" }

// 200 OK
{ "user": { ...UserResource }, "message": "Password has been updated." }
// 422 on token invalid/expired (Devise validation error)
```

### 4.5 Authorization model

- Public endpoints (no token required): `properties#index`, `properties#show`, `properties/:id/availability`, public property document downloads, and all `reference/*`.
- Authenticated endpoints: everything else.
- All write endpoints require ownership: a user can only see/modify their own appointments, offers, applications, saved properties, and saved searches. Lookup is by `current_user.id`, never trusting an `id` parameter alone.

## 5. Resource Shapes

All resource shapes are defined here once and reused across endpoints. Each is a serializer under `app/serializers/api/v1/`.

### 5.1 `UserResource`

```json
{
  "id": 42,
  "email": "buyer@example.com",
  "first_name": "Sam",
  "last_name": "Buyer",
  "full_name": "Sam Buyer",
  "mobile_number": "+447700900123",
  "language": "en",
  "saved_properties_count": 7,
  "properties_count": 0,
  "created_at": "2026-04-01T10:00:00Z"
}
```

Sensitive Devise fields (`encrypted_password`, lock counters, sign-in IPs) are never serialized.

### 5.2 `PropertySummaryResource` (used in lists)

```json
{
  "id": 101,
  "listing_state": "published",
  "sale_status": "for_sale",
  "property_type": "House",
  "tagline": "Bright 3-bed Victorian on tree-lined road",
  "address": {
    "line_1": "12 Acacia Avenue",
    "line_2": null,
    "town_city": "Bristol",
    "county": "Bristol",
    "postcode": "BS6 6XX",
    "country": "GB"
  },
  "bedrooms": 3,
  "bathrooms": 2,
  "asking_price_pence": 47500000,
  "asking_price_display": "£475,000",
  "currency": "GBP",
  "featured": false,
  "primary_photo": {
    "url": "https://.../uploads/property_photos/101/9/exterior.jpg",
    "caption": "Front of house"
  },
  "saved_by_me": true,
  "next_available_slot": "2026-05-02T14:00:00Z",
  "url": "https://gotthekeys.example/properties/101"
}
```

`saved_by_me` is `null` for unauthenticated requests and `true`/`false` when authenticated. `next_available_slot` is computed via `PropertyNextAvailableSlotLookup` (already batch-friendly).

### 5.3 `PropertyDetailResource`

Includes everything in `PropertySummaryResource` plus:

```json
{
  "description": "Set behind a leafy front garden...",
  "tenure": "freehold",
  "floor_area_sq_ft": 1450,
  "year_built": 1898,
  "refurbished_year": 2022,
  "council_tax_band": "D",
  "pets_allowed": null,
  "parking": "Off-street for 2 cars",
  "outdoor_space": "South-facing rear garden",
  "furnishing": null,
  "deposit_amount_pence": null,
  "service_charge_amount_pence": null,
  "lease_length_years": null,
  "available_from": null,
  "published_at": "2026-04-10T09:00:00Z",
  "photos": [
    { "id": 9, "url": "...", "caption": "Front of house", "primary": true, "position": 0 }
  ],
  "floor_plans": [
    { "id": 3, "url": "...", "label": "Ground floor", "position": 0 }
  ],
  "documents": [
    { "id": 5, "title": "EPC Certificate", "category": "compliance",
      "category_label": "Compliance", "visibility": "public", "position": 1,
      "download_url": "/api/v1/properties/101/documents/5/download", "is_pdf": true }
  ],
  "viewing_times": [
    { "id": 18, "start_time": "2026-05-04T18:00:00Z", "end_time": "2026-05-04T19:30:00Z" }
  ],
  "seller": {
    "id": 7,
    "full_name": "Alex Seller",
    "first_name": "Alex"
    // email/phone deliberately not exposed; contact happens via enquiry/appointment
  }
}
```

Rental-only fields (`deposit_amount_pence`, `lease_length_years`, etc.) are returned as `null` on sale listings so clients can rely on a stable key set.

### 5.4 `AppointmentResource`

```json
{
  "public_reference": "APT-20260426-7K3B",
  "property": { ...PropertySummaryResource },
  "scheduled_at": "2026-05-04T18:00:00Z",
  "ends_at":      "2026-05-04T18:30:00Z",
  "duration_minutes": 30,
  "status": "confirmed",
  "visit_outcome": null,
  "notes": "Please buzz the side gate.",
  "self_service": {
    "can_reschedule": true,
    "can_cancel":     true,
    "expires_at":     "2026-05-05T06:00:00Z"
  },
  "created_at": "2026-04-26T14:30:00Z"
}
```

`internal_notes` are admin-only and never appear in the API. The web app's `access_token` mechanism is *not* used by the iOS app — JWT auth is enough — but the server still issues access tokens for backwards compatibility with email links.

### 5.5 `OfferResource`

```json
{
  "public_reference": "OF-20260426-X9LM",
  "property": { ...PropertySummaryResource },
  "amount_pence":  46000000,
  "amount_display": "£460,000",
  "chain_position": "first_time_buyer",
  "status": "received",
  "decision_made_at": null,
  "notes": "Subject to mortgage approval.",
  "withdrawable": true,
  "created_at": "2026-04-26T14:30:00Z",
  "timeline": [
    { "event_type": "received", "from_status": null, "to_status": "received",
      "message": "Offer submitted", "occurred_at": "2026-04-26T14:30:00Z" }
  ]
}
```

### 5.6 `RentalApplicationResource`

```json
{
  "public_reference": "LET-Q2WP8ZX",
  "property": { ...PropertySummaryResource },
  "move_in_date": "2026-06-01",
  "guarantor_available": true,
  "guarantor_required":  false,
  "affordability_notes": "Salary £55k...",
  "status": "received",
  "decision_made_at": null,
  "notes": "Looking for 12-month tenancy.",
  "withdrawable": true,
  "created_at": "2026-04-26T14:30:00Z",
  "timeline": [...]
}
```

### 5.7 Enquiries — auth decision

The web app accepts enquiries from anonymous visitors (email/name/phone in the form). For v1 of the API we **require an authenticated user** to submit an enquiry, because the natural mobile flow is "tap a property in your favorites, send a message," and account creation is a 30-second flow. This:

- Removes the anti-spam burden from the API edge (the existing keyword-based detector still runs as a safety net).
- Lets us auto-fill name/email/phone from the user's profile.
- Keeps a single source of truth for "who said what."

Anonymous enquiry-by-API can be added in v1.1 with a CAPTCHA challenge if there's demand. The v1 spec explicitly defers this.

`EnquiryResource` is buyer-facing: shows what the user sent, current `status`, and `contacted_at` if a staff member has reached out, but no `internal_notes` and no admin assignment.

### 5.8 `SavedSearchResource`

```json
{
  "id": 12,
  "search_query": "victorian terrace bristol",
  "sale_status": "for_sale",
  "town_city":   "Bristol",
  "min_bedrooms": 3,
  "min_price_pence": 30000000,
  "max_price_pence": 60000000,
  "sort": "price_asc",
  "alerts_enabled": true,
  "matching_count": 14,
  "created_at": "2026-04-15T10:00:00Z"
}
```

## 6. Endpoint Reference

This section lists every endpoint, request shape, and notable status codes. Common errors (401, 403, 404, 422, 429) are described once in §7 and apply throughout.

### 6.1 `GET /api/v1/properties`

Public. Lists published properties matching filters.

Query params (all optional):

| Param | Type | Notes |
|---|---|---|
| `q` | string | Free-text on tagline/description/town |
| `sale_status` | `for_sale` \| `for_rent` | |
| `town_city` | string | Exact match |
| `min_bedrooms` | int | |
| `min_price` | int (pence) | |
| `max_price` | int (pence) | |
| `property_type` | `House` \| `Flat` | |
| `featured` | bool | |
| `sort` | enum | `price_asc`, `price_desc`, `newest`, `recommended` |
| `page` | int | default 1 |
| `per_page` | int | default 12, max 50 |

Response:

```json
{
  "data": [ ...PropertySummaryResource ],
  "meta": { "page": 1, "per_page": 12, "total_pages": 8, "total_count": 91 },
  "links": {
    "self": "/api/v1/properties?page=1",
    "next": "/api/v1/properties?page=2",
    "prev": null
  }
}
```

### 6.2 `GET /api/v1/properties/:id`

Public. 404 if not `publicly_visible?` (uses existing scope). 410 Gone if it was previously published and is now withdrawn — gives the iOS app a clean signal to remove from a "recently viewed" list.

### 6.3 `GET /api/v1/properties/:id/availability`

Public. Returns the next N bookable slots, derived from `AppointmentAvailability`.

Query params (all optional):

| Param | Type | Default | Notes |
|---|---|---|---|
| `from` | ISO 8601 datetime | `Time.current` | Start of the search window |
| `days` | int | server default | Extend search window by this many days |
| `limit` | int | 12 | Max slots to return |

```json
// GET /api/v1/properties/101/availability?from=2026-05-01&days=14&limit=5
{
  "slots": [
    {
      "starts_at":     "2026-05-02T14:00:00Z",
      "ends_at":       "2026-05-02T14:30:00Z",
      "group_viewing": false
    }
  ],
  "configuration": {
    "slot_duration_minutes": 30,
    "lead_time_hours":       4,
    "booking_window_days":   28
  }
}
```

### 6.4 `POST /api/v1/properties/:id/enquiries`

Auth required. Body: `{ "message": "...", "source_type": "general_enquiry" }`. Server fills `customer_name/email/phone` from the user. 201 returns the `EnquiryResource`.

### 6.5 `POST /api/v1/properties/:id/appointments`

Auth required. Body:

```json
{ "scheduled_at": "2026-05-04T18:00:00Z", "duration_minutes": 30, "notes": "..." }
```

Server validates against `AppointmentAvailability`. 422 with field-specific errors if the slot is unavailable. Triggers `AppointmentNotificationJob` exactly as the web flow does.

### 6.6 `PATCH /api/v1/appointments/:public_reference/reschedule`

Body: `{ "scheduled_at": "..." }`. 422 if outside `manageable_by_customer?` window or the slot is taken. Mirrors the web `cancel_self_service` / `reschedule_self_service` rules.

### 6.7 `PATCH /api/v1/appointments/:public_reference/cancel`

Body: `{ "reason": "..." }` (optional). Returns updated appointment.

### 6.8 Offers and rental applications

Symmetric to appointments. `POST` requires the property be `for_sale` (offers) or `for_rent` (applications) — the existing model validations enforce this. `PATCH .../withdraw` mirrors the `withdraw` action on the web controllers.

### 6.9 Property document downloads

`GET /api/v1/properties/:property_id/documents/:id/download` streams the document payload with `Content-Disposition: attachment`. Public documents on publicly visible properties are available without auth. Private documents are not exposed to buyer/renter clients; if an authenticated property owner requests one directly, the controller allows it.

The endpoint writes a best-effort audit log entry. If audit logging fails, the download still succeeds and the failure is logged.

### 6.10 Saved properties / searches

Saved searches honor `alerts_enabled` for future email digests. `POST /api/v1/saved_properties` is idempotent (find-or-create) and returns a lightweight confirmation rather than the full property shape:

```json
// 201 Created
{ "id": 88, "property_id": 101, "saved_at": "2026-04-26T14:30:00Z" }
```

`GET /api/v1/saved_properties` returns `PropertySummaryResource` shapes (paginated) with an extra `saved_at` field merged into each item. Attempting to save your own listing returns 422.

`GET /api/v1/saved_searches` is paginated and returns `data`, `meta`, and `links`. `POST` and `PATCH` accept API enum keys (`for_sale`, `for_rent`, `price_asc`, `price_desc`) and translate them to the model's stored labels/options.

### 6.11 Profile

`GET /api/v1/me` and `PATCH /api/v1/me` both return `{ "user": { ...UserResource } }`. `PATCH` accepts a subset: `first_name`, `last_name`, `mobile_number`, `language`. Email change requires re-confirmation (Devise's `Reconfirmable` is currently off; turning it on is a separate decision — see §10).

`DELETE /api/v1/me` immediately soft-deletes the account: anonymizes name/email/phone, revokes all refresh tokens, and rotates the JTI so any outstanding access tokens stop working. Appointments, offers, and applications are kept with `"Deleted User"` as the actor name (admin/seller continuity). Hard delete is a v2 conversation.

```json
// 200 OK
{ "deleted": true }
```

## 7. Errors

Single error envelope across the API:

```json
{
  "error": {
    "code":    "validation_failed",
    "message": "Some fields are invalid.",
    "details": [
      { "field": "email", "code": "taken", "message": "has already been taken" },
      { "field": "password", "code": "too_short", "message": "is too short (minimum is 6 characters)" },
      { "field": "password", "code": "invalid", "message": "must include at least one letter and one number" }
    ],
    "request_id": "req_01HF..."
  }
}
```

Error codes (stable, documented):

| HTTP | `code` | When |
|---|---|---|
| 400 | `bad_request` | Malformed JSON, missing required header |
| 401 | `unauthenticated` | No/invalid/expired access token |
| 401 | `token_expired` | Specifically for expired access tokens (so iOS can trigger refresh) |
| 401 | `refresh_invalid` | Refresh token reused/revoked/expired |
| 403 | `forbidden` | Authenticated but not allowed (e.g. someone else's appointment) |
| 404 | `not_found` | Resource not visible or doesn't exist |
| 409 | `conflict` | Slot already booked, offer not withdrawable, listing under offer |
| 410 | `gone` | Property withdrawn after being indexed |
| 422 | `validation_failed` | ActiveRecord validation errors |
| 423 | `locked` | Devise `Lockable` triggered |
| 429 | `rate_limited` | Rack::Attack throttled; `Retry-After` header set |
| 500 | `internal_error` | Unhandled; logged with `request_id` |

`request_id` echoes a per-request UUID also returned in the `X-Request-Id` response header — makes Sentry/log correlation trivial when iOS reports a bug.

## 8. Cross-Cutting Concerns

### 8.1 Pagination

Page-based via Kaminari (already in the Gemfile). Every collection endpoint returns the `meta` and `links` blocks shown in §6.1. `per_page` capped at 50 server-side; requesting more silently clamps.

### 8.2 Sorting and filtering

Filtering rides on `Property.filter`, the same model-level query used by public catalogue search paths. API enum keys are translated at the controller boundary before they hit the model.

### 8.3 Localization

`Accept-Language: en, fr;q=0.8` is parsed by a before_action that sets `I18n.locale` for the duration of the request. Fall back order: explicit header → `current_user.language` → `I18n.default_locale`. All user-visible strings (validation messages, status labels) honor this.

### 8.4 Rate limiting

Existing Rack::Attack rules already cover `/users/sign_in`, password reset, etc. We add API-specific throttles:

- `POST /api/v1/auth/login`: 10/5min/IP, 5/5min/email (matches web)
- `POST /api/v1/auth/refresh`: 60/min/user (generous; clients may be aggressive)
- All other authenticated requests: 600/min/user (10/sec sustained)
- Public catalogue browsing: 300/min/IP

Throttled responses use the standard 429 envelope and include a `Retry-After` header.

### 8.5 CORS

Add `rack-cors` to the Gemfile. Allow:

- iOS app: no CORS needed (native URLSession ignores it)
- Future web SPA: explicit allow-list of origins, configured per environment
- Credentials disabled — auth is via Bearer header, not cookies

### 8.6 Caching

`Cache-Control: public, max-age=60` on `properties#index` and `properties#show` for unauthenticated requests; `private, no-store` on authenticated responses. ETag/Last-Modified on property details so iOS can use conditional GETs.

`reference/*` endpoints get long max-age (1 day) plus an ETag derived from `BookingConfiguration#updated_at`.

### 8.7 Image and document URLs

In v1, photos/floor plans/documents are served from `/public/uploads/...` exactly as today. The serializer just exposes the absolute URL. When the codebase migrates to ActiveStorage (a known follow-up — current uploads are bespoke), the serializer changes but the contract stays the same.

Documents go through `GET /api/v1/properties/:id/documents/:doc_id/download`, which streams the file via `send_data` with `Content-Disposition: attachment`. Public documents are accessible without auth; private documents require the property owner. Audit log entries are written as in the web flow on a best-effort basis.

### 8.8 Reference endpoint details

`GET /api/v1/reference/booking_window` returns the full `BookingConfiguration` relevant to iOS slot rendering. ETag-based conditional GET is supported (respond with your last received `ETag` in `If-None-Match`; server returns 304 if unchanged).

```json
{
  "slot_duration_minutes":    30,
  "booking_window_days":      28,
  "lead_time_hours":          4,
  "buffer_minutes":           10,
  "office_opens_at":          "09:00",
  "office_closes_at":         "18:00",
  "open_weekdays":            [1, 2, 3, 4, 5],
  "supported_slot_durations": [30, 45, 60]
}
```

`open_weekdays` uses ISO weekday numbers (1=Monday … 7=Sunday). `Cache-Control: public, max-age=300`.

### 8.9 Push notifications (out of scope)

Acknowledged but deferred. The `device_id` captured at login means we can register APNs tokens against a refresh token row in v1.1 without any schema churn beyond adding columns.

## 9. Versioning, Deprecation, Stability

- Breaking changes go to `/api/v2/...`. Non-breaking additions (new fields, new endpoints, new optional params) ship inside v1.
- Deprecated v1 fields are marked `"deprecated": true` in the OpenAPI doc and announced via a `Sunset` HTTP header on responses where the deprecation matters.
- v1 is committed-to for 12 months minimum after the iOS app ships.

## 10. Product Decisions And Follow-Ups

1. **Email confirmation.** JSON confirmation endpoints are not part of the current v1 routes. Add them only if the mobile signup policy changes.
2. **Email change → re-confirmation.** Devise's `Reconfirmable` is currently off. Turning it on affects the web app too. Recommended follow-up: add a separate "change email" endpoint in v1.1 with explicit re-confirmation if needed.
3. **Anonymous enquiries via API.** v1 intentionally requires auth for API enquiries.
4. **Account deletion semantics.** v1 immediately anonymizes PII, revokes refresh tokens, and rotates `jti`; hard delete remains a legal/product follow-up.
5. **APNs / push.** Not in v1. The current `device_id` field leaves room to add APNs tokens against refresh-token rows later.
6. **OpenAPI maintenance.** `docs/api/v1-openapi.yaml` is hand-authored for v1 and committed with the Postman collection. RSwag generation remains a follow-up if the API grows quickly.

## 11. Implementation Status

Implemented in the current API work:

- Gems/config: `devise-jwt`, `rack-cors`, API Rack::Attack rules, JWT initializer, CORS initializer.
- Migrations: `users.jti`, `api_refresh_tokens`.
- Controllers/concerns: API base controller, error handling, localization, pagination, JWT auth.
- Auth: register, login, logout, refresh rotation/reuse detection, password reset request/update.
- Catalogue: properties index/detail/availability, document downloads, public caching headers.
- Personal data: profile show/update/delete, saved properties, saved searches.
- Transactional: enquiries, appointments, offers, rental applications.
- Reference: property types, sale statuses, sort options, languages, booking window.
- Docs: Markdown spec, OpenAPI 3.1 YAML, and Postman collection under `docs/api/`.

### Test strategy
- RSpec request specs per endpoint, organized under `spec/requests/api/v1/`.
- Auth specs cover token rotation, reuse detection, lockout, rate limiting.
- Shared examples for "requires auth" and "owner-scoped".
- Capybara stays for the web app; the API layer is API-only.

### Out-of-scope follow-ups (tracked separately)
- ActiveStorage migration for photos/floor plans/documents.
- APNs push notifications.
- Seller and admin API surfaces.
- Web SPA built on top of v1.

---

## Appendix A — File layout

```
app/
  controllers/api/v1/
    base_controller.rb
    auth/
      registrations_controller.rb
      sessions_controller.rb
      refreshes_controller.rb
      passwords_controller.rb
    me_controller.rb
    properties_controller.rb
    properties/
      availability_controller.rb
      enquiries_controller.rb
      appointments_controller.rb
      offers_controller.rb
      rental_applications_controller.rb
      documents_controller.rb
    appointments_controller.rb
    offers_controller.rb
    rental_applications_controller.rb
    saved_properties_controller.rb
    saved_searches_controller.rb
    reference_controller.rb
  controllers/concerns/api/v1/
    jwt_authenticatable.rb
    paginated.rb
    localized.rb
    error_handling.rb
  serializers/api/v1/
    user_resource.rb
    property_summary_resource.rb
    property_detail_resource.rb
    photo_resource.rb
    floor_plan_resource.rb
    document_resource.rb
    appointment_resource.rb
    offer_resource.rb
    rental_application_resource.rb
    enquiry_resource.rb
    saved_search_resource.rb
  models/
    api_refresh_token.rb           # new
config/
  initializers/
    devise_jwt.rb                  # new
    cors.rb                        # new
    rack_attack.rb                 # appended
spec/
  requests/api/v1/
    auth/...
    properties_spec.rb
    appointments_spec.rb
    offers_spec.rb
    rental_applications_spec.rb
    saved_properties_spec.rb
    saved_searches_spec.rb
    me_spec.rb
docs/
  api/
    v1-spec.md                     # this file
    v1-openapi.yaml                # hand-authored contract, committed
    v1-postman.json                # committed
```
