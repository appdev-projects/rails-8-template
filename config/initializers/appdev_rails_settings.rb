# AppDev Rails Settings (Phase 1 - Beginner)
# Consolidated Rails configuration for AppDev projects

Rails.application.configure do
  # Allow unsafe redirects (for student convenience).
  # Rails 8.1 renamed the setting; the guard keeps this file boot-safe on
  # both sides of the fleet upgrade window (8.0 doesn't know the new name).
  if Rails.gem_version >= Gem::Version.new("8.1")
    config.action_controller.action_on_open_redirect = :log
  else
    config.action_controller.raise_on_open_redirects = false
  end

  # Allow envoy.fyi to frame the app
  config.content_security_policy do |policy|
    policy.frame_ancestors :self, "https://envoy.fyi"
  end
end

# Phase 1 beginner-friendly security settings
# These relax Rails security defaults for learning purposes
Rails.application.config.action_controller.default_protect_from_forgery = false
Rails.application.config.active_record.belongs_to_required_by_default = false

# Phase 1 routes are written with hash arguments on purpose, e.g.
# get("/lists", { :controller => "lists", :action => "index" }), because the
# curriculum teaches that shape. Rails 8.1 deprecates it ahead of 8.2 and
# prints two warnings per route on every boot, grade run and server start.
# Drop only that message; anything else ActionDispatch deprecates still
# shows. Revisit at the Rails 8.2 upgrade, when the routes themselves change.
if Rails.gem_version >= Gem::Version.new("8.1") && Rails.gem_version < Gem::Version.new("8.2")
  Rails.application.config.after_initialize do
    previous = ActionDispatch.deprecator.behavior
    ActionDispatch.deprecator.behavior = lambda do |message, callstack, deprecator|
      next if message.include?("received a hash argument")
      previous.each { |behavior| behavior.call(message, callstack, deprecator) }
    end
  end
end
