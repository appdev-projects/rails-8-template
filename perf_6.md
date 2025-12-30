# Ultimate Rails 8 Performance & Memory Guide for Render (Free Tier)

This guide consolidates the most effective strategies to run a Rails 8 application efficiently on Render.com's Free Tier (512MB RAM). It prioritizes **stability** (avoiding Out-Of-Memory crashes) over maximum throughput.

---

## 🛑 Phase 1: Critical Configuration (The "Must Haves")

These changes provide the massive memory savings required to fit in 512MB.

### 1. Force Puma to "Single Mode"
**Why:** Running multiple workers doubles/triples memory usage. 512MB is only enough for **one** Ruby process.
**Action:**
- Set `WEB_CONCURRENCY: 1` in `render.yaml`.
- Ensure `config/puma.rb` respects this:
  ```ruby
  # config/puma.rb
  web_concurrency = ENV.fetch("WEB_CONCURRENCY", 0).to_i
  workers web_concurrency if web_concurrency > 1
  ```

### 2. Tune Memory Allocator
**Why:** Ruby interacts poorly with the default Linux memory allocator, causing fragmentation ("bloat").
**Action:**
- Set `MALLOC_ARENA_MAX: 2` in `render.yaml`.

### 3. Consolidate Database Connections
**Why:** Default Rails 8 setups use 4 separate DB pools (Primary, Cache, Queue, Cable). Maintaining 4 pools wastes connections and memory.
**Action:**
- Modify `config/database.yml` (production) to share the `primary` configuration:
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

### 4. Cap Thread Count
**Why:** More threads = more memory per request.
**Action:**
- Set `RAILS_MAX_THREADS: 3` in `render.yaml`.
- Ensure `database.yml` pool size matches: `pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 3 } %>`.

---

## 🧹 Phase 2: Application Hygiene

Reduce the static footprint of your application.

### 1. Gemfile Cleanup
**Why:** Every loaded gem eats RAM.
**Action:**
- Move development-only gems (`faker`, `rubocop`, `web-console`, `annotate`, `appdev_support`) to `group :development, :test`.
- Ensure `render.yaml` sets `BUNDLE_WITHOUT: "development:test"`.

### 2. Disable Unused Frameworks
**Why:** Rails loads Action Mailbox, Action Text, and Active Storage by default. If you don't use them, they are dead weight.
**Action:**
- Comment them out in `config/application.rb`:
  ```ruby
  # require "action_mailbox/engine"
  # require "action_text/engine"
  # require "action_cable/engine" # Only if not using WebSockets
  ```

---

## ⚙️ Phase 3: Background Jobs Strategy

**The Dilemma:**
- **Separate Worker Service:** Costs $$ (Not on free plan).
- **Async Adapter:** Free, low memory, but **loses jobs on restart**.
- **Solid Queue in Puma:** Durable, but uses more shared memory.

**Recommendation:**
Use **Solid Queue in Puma** but watch memory closely. It is the best balance for a functional student app.

**Action:**
- Set `SOLID_QUEUE_IN_PUMA: true` in `render.yaml`.
- *Fallback:* If you still hit OOM errors, switch to `RAILS_QUEUE_ADAPTER: async` and `SOLID_QUEUE_IN_PUMA: false`.

---

## 🚀 Phase 4: Advanced Optimizations

### 1. Use Docker Runtime (for `jemalloc`)
**Why:** Your `Dockerfile` installs `libjemalloc2`, a superior memory allocator that reduces usage by 10-20%. The "Native Ruby" runtime does not use this.
**Action:**
- Switch your Render service Runtime to **Docker**.
- This also gives you `thruster` (static asset acceleration) for free.

### 2. HTTP Caching
**Why:** The fastest request is one you don't serve.
**Action:**
- Use `stale?` checks in controllers:
  ```ruby
  def show
    @post = Post.find(params[:id])
    render :show if stale?(@post)
  end
  ```

---

## ✅ Summary Checklist for `render.yaml`

```yaml
services:
  - type: web
    runtime: ruby # or 'docker' for better perf
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
      - key: BUNDLE_WITHOUT
        value: "development:test"
```
