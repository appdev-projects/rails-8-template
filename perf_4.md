# Comprehensive Memory Optimization Plan for Render.com

This document consolidates the most effective strategies for running a Rails 8 application on Render's free tier (512MB RAM). It balances stability, feature completeness (durable jobs), and resource efficiency.

## 1. Optimize Web Server Mode (Critical)

**Strategy:** Force Puma into "Single Mode" (Threads only).
**Why:** Running multiple workers ("Cluster Mode") forks the entire application, doubling memory usage. Single mode is sufficient for most student/low-traffic apps and saves ~40-50% memory.

**Action:**
- Set `WEB_CONCURRENCY` to `1` in `render.yaml`.
- **Fix `config/puma.rb`:** Ensure it doesn't default to 1 worker (which triggers cluster mode). It should logically result in 0 workers when `WEB_CONCURRENCY` is 1.

```ruby
# config/puma.rb
web_concurrency = ENV.fetch("WEB_CONCURRENCY", 0).to_i
# Only enable workers if explicitly set > 1
workers web_concurrency if web_concurrency > 1
```

## 2. Consolidate Database Connections (High Impact)

**Strategy:** Share a single PostgreSQL database connection pool for the app, cache, queue, and cable.
**Why:** The default `database.yml` defines 4 separate databases (`primary`, `cache`, `queue`, `cable`). Even with a small pool size, maintaining 4 separate pools multiplies the memory overhead of maintaining those connections.
**Impact:** ~15-20% memory reduction.

**Action:** Update `config/database.yml` production section to share the primary configuration:

```yaml
production:
  primary: &primary_production
    <<: *default
    url: <%= ENV["DATABASE_URL"] %>
  cache:
    <<: *primary_production
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    migrations_paths: db/cable_migrate
```

## 3. Tune Memory Allocator (High Impact)

**Strategy:** Use Linux memory allocator tuning.
**Why:** Ruby creates high memory fragmentation on the default glibc allocator.
**Impact:** ~20-30% reduction in "bloated" (reserved but unused) memory.

**Action:** Add to `render.yaml` environment variables:
```yaml
- key: MALLOC_ARENA_MAX
  value: 2
```

## 4. Efficient Background Jobs

**Strategy:** Run Solid Queue inside Puma *but* strictly limit its resource usage.
**Why:**
- **External Worker:** Costs money/RAM you don't have.
- **Async (In-Memory):** Loses jobs on restart (bad for learning durability).
- **Solid Queue in Puma:** Best compromise. It shares the app's loaded memory.

**Action:**
- Enable `SOLID_QUEUE_IN_PUMA: true`.
- **Crucial:** Ensure database pooling (step 2) is done, otherwise Solid Queue opens its own pool, negating the benefits.

## 5. Thread Management

**Strategy:** Cap threads to match the database pool.
**Why:** High thread counts increase memory per request and require larger DB pools.

**Action:**
- Set `RAILS_MAX_THREADS` to `3` (or `2` if strictly needed) in `render.yaml`.
- Ensure `database.yml` uses this variable for its pool size: `pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 3 } %>`.

## 6. Gem Hygiene

**Strategy:** Audit and remove duplicate/heavy gems.
**Why:** Every loaded gem consumes persistent memory.

**Action:**
- **Pagination:** Choose *one* (`pagy` is lighter than `kaminari`). Remove the other.
- **Environment Groups:** Ensure gems like `faker`, `rubocop`, `web-console`, `better_errors` are strictly in `group :development, :test`.

## Summary Configuration (`render.yaml`)

```yaml
services:
  - type: web
    # ...
    envVars:
      - key: RAILS_ENV
        value: production
      - key: WEB_CONCURRENCY
        value: 1
      - key: RAILS_MAX_THREADS
        value: 3
      - key: MALLOC_ARENA_MAX
        value: 2
      - key: SOLID_QUEUE_IN_PUMA
        value: true
      - key: SECRET_KEY_BASE
        generateValue: true
      - key: DATABASE_URL
        sync: false
```
