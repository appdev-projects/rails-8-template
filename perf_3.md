# Render.com Memory Audit (Rails 8 Template)

This template is intended to run on Render’s free plan, which is memory constrained. Most production OOMs are caused by accidentally running **too many Ruby processes** (Puma workers) and/or running **background jobs inside the web process**.

## Likely OOM causes in this template (before fixes)

- **Multiple Puma workers (`WEB_CONCURRENCY > 1`)**: each worker is a full Ruby/Rails process with its own heap. Doubling workers often doubles memory.
- **Solid Queue supervisor running inside Puma** (`SOLID_QUEUE_IN_PUMA=true`): adds job processing threads/processes to the same memory budget as the web server.
- **Not explicitly setting production mode on Render**: if `RAILS_ENV`/`RACK_ENV` aren’t set, you risk “development-ish” behavior (code reloading, extra middleware, dev/test gems), which is significantly heavier.
- **Default-group gems loaded in production**: gems not scoped to `:development`/`:test` get `require`’d in production via `Bundler.require(*Rails.groups)`.

## Recommended baseline for Render free plan

Use these defaults unless you’ve upgraded the plan:

- `RAILS_ENV=production` and `RACK_ENV=production`
- `WEB_CONCURRENCY=1`
- `RAILS_MAX_THREADS=3` (if you still see OOMs, try `2`)
- `MALLOC_ARENA_MAX=2` (helps reduce allocator memory bloat on glibc)
- `BUNDLE_WITHOUT=development:test`
- **Do not run Solid Queue inside Puma**; default jobs to in-process `:async`

These settings prioritize “stays up” over max throughput, which is usually what you want for student projects.

## Background jobs: what to do when you need them

- **Free plan (recommended default)**: keep `RAILS_QUEUE_ADAPTER=async`.
  - Pros: lowest memory overhead.
  - Cons: jobs are in-memory; jobs can be lost on restart; not suitable for critical background work.

- **Paid plan / more headroom**: switch back to Solid Queue and run jobs in a separate Render service.
  - Web service: `RAILS_QUEUE_ADAPTER=solid_queue`, `SOLID_QUEUE_IN_PUMA=false`
  - Worker service (example start command): `./bin/jobs start`
  - Keep worker concurrency small at first (e.g. `JOB_CONCURRENCY=1`, and consider reducing `threads` in `config/queue.yml` if needed).

## Optional further reductions (only if students don’t need these features)

These are “last mile” wins compared to fixing worker/job concurrency:

- **Disable unused Rails frameworks** in `config/application.rb` (e.g. Action Cable, Action Text, Action Mailbox, Active Storage) to reduce boot time and memory.
- **Trim default-group gems**: every gem in the default group is loaded in production. If the course doesn’t require a gem for deployed apps, move it to `:development, :test` or remove it.

## Quick verification checklist (on Render)

- Confirm the app logs show it booting in **production** (`RAILS_ENV=production`).
- Confirm you only have **one web process** (no extra Puma workers).
- If you’re on the free plan, confirm you are **not** running Solid Queue inside Puma and that jobs are `:async`.

## Changes applied in this repo

- `render.yaml` sets production mode explicitly, keeps `WEB_CONCURRENCY=1`, caps thread counts, disables in-Puma Solid Queue, and defaults jobs to `:async`.
- `config/puma.rb` treats `SOLID_QUEUE_IN_PUMA` as a real boolean so `"false"` won’t accidentally enable it.
- `Gemfile` moves dev/test-only gems out of production, and `config/initializers/appdev_support.rb` only initializes in dev/test.
- `bin/render-start.sh` uses `exec` and explicitly binds/ports for Render and defaults to production.

