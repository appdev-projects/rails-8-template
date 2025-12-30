# Performance and Memory Audit Recommendations

The following recommendations are designed to reduce memory usage for your Rails 8 application on Render.com, specifically targeting the "Free" plan limits.

## 1. Reduce Puma Workers (`WEB_CONCURRENCY`)

**Issue:** The current configuration in `render.yaml` sets `WEB_CONCURRENCY` to `2`.
```yaml
- key: WEB_CONCURRENCY
  value: 2
```
This forces Puma to run in "Clustered Mode" with 2 worker processes. Each worker forks the application, effectively doubling the memory footprint required for the Rails application code. On a memory-constrained environment (like the free plan), this often leads to Out-Of-Memory (OOM) kills.

**Recommendation:**
Set `WEB_CONCURRENCY` to `1` (or effectively 0). This runs Puma in "Single Mode" (threads only). While this limits theoretical maximum throughput on multi-core systems, it drastically reduces memory usage, which is the bottleneck here.

**Action:**
Update `render.yaml`:
```yaml
- key: WEB_CONCURRENCY
  value: 1
```

## 2. Tune Memory Allocator (`MALLOC_ARENA_MAX`)

**Issue:** The default glibc memory allocator can create fragmentation in multi-threaded Ruby applications, causing "bloat" where memory is reserved but not used.

**Recommendation:**
Set the `MALLOC_ARENA_MAX` environment variable to `2`. This is a standard optimization for Ruby apps to trade a tiny bit of performance for significantly tighter memory usage.

**Action:**
Add to `render.yaml` environment variables:
```yaml
- key: MALLOC_ARENA_MAX
  value: 2
```

## 3. Run Solid Queue in Puma

**Issue:** Rails 8 uses Solid Queue for background jobs. You need a way to process these jobs. Running a separate "worker" service costs money and memory. Running a separate process inside the web service also consumes more RAM.

**Recommendation:**
Use the `solid_queue` Puma plugin to run job processing threads *inside* the web process. This shares the memory of the Rails app between web requests and background jobs.

**Action:**
1. Ensure your `config/puma.rb` has this line (it currently does):
   ```ruby
   plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
   ```
2. Enable it in `render.yaml`:
   ```yaml
   - key: SOLID_QUEUE_IN_PUMA
     value: true
   ```

## 4. Puma Configuration Adjustment

**Issue:** The `config/puma.rb` script sets `workers` based on `WEB_CONCURRENCY` if the variable exists. If you set `WEB_CONCURRENCY` to 1, some configurations might still attempt to use cluster mode (workers = 1), which has higher overhead than single mode (workers = 0).

**Recommendation:**
Update `config/puma.rb` to explicitly only enable workers if the count is greater than 1.

**Action:**
Update `config/puma.rb`:
```ruby
# ...
web_concurrency = ENV.fetch("WEB_CONCURRENCY", 0).to_i
workers web_concurrency if web_concurrency > 1
# ...
```

## Summary of `render.yaml` Changes

```yaml
services:
  - type: web
    # ...
    envVars:
      - key: SECRET_KEY_BASE
        generateValue: true
      - key: DATABASE_URL
        sync: false
      - key: WEB_CONCURRENCY
        value: 1
      - key: MALLOC_ARENA_MAX
        value: 2
      - key: SOLID_QUEUE_IN_PUMA
        value: true
```
