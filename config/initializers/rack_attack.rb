# A generous per-IP perimeter so one runaway client (or a vulnerability
# scanner) cannot monopolize a 512 MB single-process app, plus a blocklist for
# the WordPress/PHP probes every public hostname receives within days.
#
# Counters live in process memory, not in Solid Cache, so perimeter traffic
# never adds load to the database. They reset on restart and are per instance,
# which is fine for the one-instance free-tier profile this template ships.
if Object.const_defined?("Rack::Attack")
  require Rails.root.join("lib/perimeter_client_ip")

  class Rack::Attack
    # Probes for software this app does not run. Anchored to the end of the
    # path so an Active Storage blob named "photo.php.jpg" is not caught, and
    # Active Storage routes are exempted outright.
    SCANNER_PATTERN = %r{\.php(?:\z|/)|/wp-(?:admin|content|includes|login)|/\.(?:env|git)(?:/|\z)}i

    blocklist("php and wordpress probes") do |req|
      !req.path.start_with?("/rails/active_storage/") && req.path.match?(SCANNER_PATTERN)
    end

    safelist("healthcheck and assets") do |req|
      req.path == "/up" || req.path == "/assets" || req.path.start_with?("/assets/")
    end

    # 300 requests per 5 minutes per IP: a sustained budget, so a burst of tabs
    # is fine. A classroom behind one NAT shares it; raise RACK_ATTACK_LIMIT
    # for shared-IP audiences.
    throttle("requests by ip", limit: ->(_req) { Rails.application.config.x.rack_attack_limit }, period: 300) do |req|
      PerimeterClientIp.call(req)
    end

    self.throttled_responder = ->(request) do
      match_data = request.env["rack.attack.match_data"] || {}
      period = match_data.fetch(:period, 60).to_i
      epoch_time = match_data.fetch(:epoch_time, Time.now.to_i).to_i
      retry_after = period - (epoch_time % period)
      [429, { "content-type" => "text/plain; charset=utf-8", "retry-after" => retry_after.to_s },
       ["Rate limit exceeded. Try again in #{retry_after} seconds.\n"]]
    end
  end

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)
  Rails.application.config.x.rack_attack_limit = Integer(ENV.fetch("RACK_ATTACK_LIMIT", "300"), 10)
end
