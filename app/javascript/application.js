// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
// The dev toolbar gem is development-only, so its importmap pin is absent in
// production. A dynamic import fails quietly there instead of breaking the
// whole module graph (and every Stimulus controller with it).
import("dev_toolbar").catch(() => {})

// Change to true to enable Turbo Drive
Turbo.session.drive = false
