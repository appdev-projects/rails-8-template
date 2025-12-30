# Advanced Performance Optimizations

Based on further analysis of the "Complete Guide to Rails Performance" and your project structure, here are advanced strategies.

## 1. Disable Unused Rails Frameworks

**Why:** Rails 8 loads powerful frameworks by default that many simple CRUD apps don't use. Each loaded framework consumes boot-time memory.
**Impact:** Saves ~10-30MB RAM.

**Action:**
Edit `config/application.rb` and comment out frameworks you aren't using. Common candidates for removal:

```ruby
require "rails"
# ...
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"  # <-- Disable if not processing inbound email
# require "action_text/engine"     # <-- Disable if not using Trix/Rich Text
require "action_view/railtie"
# require "action_cable/engine"    # <-- Disable if not using WebSockets
```

## 2. Consider Docker Runtime for `jemalloc`

**Observation:** Your repository contains a production-ready `Dockerfile` that already installs `libjemalloc2`.
**Why:** `jemalloc` is a specialized memory allocator that often performs better than the standard system allocator (`glibc`), reducing fragmentation and overall memory usage by 10-20%.

**Action:**
Instead of using the "Native Ruby" runtime in Render (`runtime: ruby`), you can switch your Render service to use **Docker**.
1. Update `render.yaml` (or change setting in dashboard) to use `runtime: docker`.
2. This automatically uses your `Dockerfile`, which:
   - Installs `jemalloc`.
   - Uses `thruster` (an accelerated HTTP/2 proxy) in front of Puma.
   - Ensures a consistent, optimized environment.

*Note: Docker builds on the free tier might be slightly slower than native builds, but the runtime performance is usually superior.*

## 3. Audit "require 'rails/all'"

**Check:** Ensure you are NOT using `require "rails/all"` in `config/application.rb`.
**Status:** Your app already correctly requires individual frameworks. (Good job!)

## 4. Leverage HTTP Caching

**Why:** Avoiding server work entirely is the best memory optimization.
**Action:** Use `ETags` and `Last-Modified` headers in your controllers for public data.
```ruby
def show
  @product = Product.find(params[:id])
  # If the client has a fresh copy, this returns 304 Not Modified immediately
  # and stops further processing/rendering.
  if stale?(@product)
    render :show
  end
end
```
