# Memory Optimization Recommendations for Render.com Deployment

This document outlines recommendations for reducing memory usage on Render.com's free tier (512MB RAM).

---

## Critical Issues

### 1. WEB_CONCURRENCY=2 on Free Tier

Render's free tier has ~512MB RAM. Running 2 Puma workers is too aggressive for this constraint.

**Current:** `render.yaml` sets `WEB_CONCURRENCY: 2`

**Recommendation:** Change to `WEB_CONCURRENCY: 1`:

```yaml
- key: WEB_CONCURRENCY
  value: 1
```

**Expected impact:** ~40-50% memory reduction

---

### 2. Four Separate PostgreSQL Databases

The `config/database.yml` configures 4 separate databases in production:
- `primary` - main application data
- `cache` - for Solid Cache
- `queue` - for Solid Queue
- `cable` - for Solid Cable

Each database connection pool consumes significant memory. With pool size 5, that's potentially 20 connections total.

**Recommendation:** Consolidate to a single database. The Solid* gems can share the primary PostgreSQL database using different tables.

> **Note:** SQLite is not an option on Render's free tier because it uses an ephemeral filesystem. Any SQLite databases would be wiped on every deploy or restart, losing cached data, pending background jobs, and WebSocket state.

**Option A: Share the primary PostgreSQL database (recommended)**

Remove the separate `database:` overrides so all use the same database but different tables:

```yaml
# config/database.yml
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

**Option B: Disable Solid* features entirely**

If students don't need background jobs or WebSockets, disable these features:

```ruby
# config/environments/production.rb

# Use async adapter instead of Solid Queue (jobs run in-process)
config.active_job.queue_adapter = :async

# Use in-memory cache instead of Solid Cache (simpler, lower memory)
config.cache_store = :memory_store, { size: 16.megabytes }
```

Then remove the `cache`, `queue`, and `cable` database entries entirely.

**Expected impact:** ~15-20% memory reduction

---

### 3. Missing Puma Workers Configuration

The `config/puma.rb` doesn't explicitly set workers - it relies on `WEB_CONCURRENCY` but doesn't call the `workers` method. This may cause unexpected behavior.

**Recommendation:** Add to `config/puma.rb`:

```ruby
workers ENV.fetch("WEB_CONCURRENCY", 0)
preload_app!
```

The `preload_app!` directive enables Copy-on-Write memory sharing between workers, which is essential when running multiple workers.

---

## High Impact Recommendations

### 4. Add Ruby GC Tuning Environment Variables

Add these to `render.yaml`:

```yaml
- key: MALLOC_ARENA_MAX
  value: 2
- key: RUBY_GC_HEAP_GROWTH_FACTOR
  value: 1.1
```

`MALLOC_ARENA_MAX=2` is critical for reducing memory fragmentation in glibc's malloc implementation. This is one of the most effective memory optimizations for Ruby on Linux.

**Expected impact:** ~20-30% memory reduction

---

### 5. Reduce Thread Count

The default thread count is 3. Reducing to 2 saves memory while maintaining reasonable concurrency.

**Recommendation:** Add to `render.yaml`:

```yaml
- key: RAILS_MAX_THREADS
  value: 2
```

The `database.yml` already uses `RAILS_MAX_THREADS` for pool size, so this will automatically align.

**Expected impact:** ~10% memory reduction

---

### 6. Consider jemalloc

jemalloc is an alternative memory allocator that significantly reduces Ruby memory usage and fragmentation.

**Option A:** Use the jemalloc gem (simpler):

```ruby
# Gemfile
gem 'jemalloc'
```

**Option B:** Install jemalloc system-wide in your build script.

**Expected impact:** ~10-20% memory reduction

---

## Moderate Impact Recommendations

### 7. Review Heavy Gems

Some gems in the Gemfile add notable memory overhead:

| Gem | Concern | Recommendation |
|-----|---------|----------------|
| `ransack` | Heavy query builder, loads many dependencies | Consider simpler query building |
| `ai-chat` | Unknown memory profile | Monitor usage |
| `rollbar` | Queues errors in memory before sending | Ensure queue limits are set |
| `kaminari` + `pagy` | Both pagination gems included | Pick one (pagy is lighter) |
| `carrierwave` + `cloudinary` | File upload handling | Memory spikes during uploads |

---

### 8. Disable Unused Solid* Features

If students don't use background jobs, Solid Queue adds unnecessary overhead. Similarly for Solid Cable if WebSockets aren't used.

To disable Solid Queue in Puma, ensure `SOLID_QUEUE_IN_PUMA` is not set.

To disable entirely, remove from `config/environments/production.rb`:

```ruby
# Comment out if not using background jobs
# config.active_job.queue_adapter = :solid_queue
```

---

### 9. Align Connection Pool Size

The default pool is 5 but `RAILS_MAX_THREADS` would be 2-3. These should match.

The current `database.yml` already handles this:

```yaml
pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

Change the default from 5 to match your thread count:

```yaml
pool: <%= ENV.fetch("RAILS_MAX_THREADS", 2) %>
```

---

## Suggested render.yaml Configuration

```yaml
services:
  - type: web
    name: my-app-name
    runtime: ruby
    plan: free
    buildCommand: "./bin/render-build.sh"
    startCommand: "./bin/render-start.sh"
    envVars:
      - key: SECRET_KEY_BASE
        generateValue: true
      - key: DATABASE_URL
        sync: false
      - key: WEB_CONCURRENCY
        value: 1                    # Reduced from 2
      - key: RAILS_MAX_THREADS
        value: 2                    # Explicitly set lower
      - key: MALLOC_ARENA_MAX
        value: 2                    # Critical for memory fragmentation
      - key: RUBY_GC_HEAP_GROWTH_FACTOR
        value: 1.1                  # Gentler heap growth
```

---

## Summary Priority Table

| Priority | Change | Expected Impact | Effort |
|----------|--------|-----------------|--------|
| 1 | `WEB_CONCURRENCY=1` | ~40-50% reduction | Trivial |
| 2 | `MALLOC_ARENA_MAX=2` | ~20-30% reduction | Trivial |
| 3 | Consolidate/simplify databases | ~15-20% reduction | Medium |
| 4 | `RAILS_MAX_THREADS=2` | ~10% reduction | Trivial |
| 5 | Add `preload_app!` to Puma | Better memory sharing | Trivial |
| 6 | Add jemalloc | ~10-20% reduction | Low |
| 7 | Remove duplicate gems (kaminari/pagy) | Minor | Low |

---

## Monitoring

After implementing changes, monitor memory usage via:

1. Render.com dashboard metrics
2. Add `get_process_mem` gem for application-level monitoring
3. Consider `derailed_benchmarks` gem for memory profiling during development
