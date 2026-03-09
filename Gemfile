source "https://rubygems.org"

gem "rails", "~> 8.0.2"               # The web framework
gem "propshaft"                       # Asset pipeline (CSS, JS, images)
gem "pg", "~> 1.1"                    # PostgreSQL database adapter
gem "puma", ">= 5.0"                  # Web server
gem "importmap-rails"                 # JavaScript with ESM import maps
gem "turbo-rails"                     # Hotwire page acceleration (SPA-like)
gem "stimulus-rails"                  # Hotwire JavaScript framework
gem "solid_cache"                     # Database-backed Rails.cache
gem "solid_queue"                     # Database-backed Active Job
gem "solid_cable"                     # Database-backed Action Cable
gem "bootsnap", require: false        # Faster boot times via caching
gem "thruster", require: false        # HTTP caching/compression for Puma
gem "tzinfo-data", platforms: %i[windows jruby] # Timezone data for Windows/JRuby
gem "dotenv"                          # Load environment variables from .env
gem "http"                            # Simple HTTP client for APIs
gem "rollbar"                         # Error tracking in production
gem "appdev_support"                  # Learning helpers (nicer error messages, etc.)
gem "cgi" # Required for Ruby 4.0+ (removed from stdlib)
gem "tsort" # Required for Ruby 4.0+ (moving out of default gems)

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude" # Ruby debugger
  gem "rspec-rails", "~> 8.0" # Testing framework
  gem "grade_runner", "~> 0.0.16" # Automated grading
end

group :development do
  gem "amazing_print"                 # Pretty print Ruby objects in console
  gem "annotaterb"                    # Add schema info to model files
  gem "better_errors"                 # Better error pages with console
  gem "binding_of_caller", "~> 2.0.0" # Required for better_errors console
  gem "dev_toolbar", "~> 2.1.0"       # Development toolbar
  gem "draft_generators", "~> 0.0.5"  # Beginner-friendly Rails generators
  gem "haikunator"                    # Generate random names (for databases)
  gem "htmlbeautifier"                # Format HTML/ERB files
  gem "pry-rails"                     # Better Rails console
  gem "rails_db", "~> 2.5.0"          # Database viewer in browser
  gem "rails-erd"                     # Generate ER diagrams
  gem "rufo"                          # Ruby code formatter
  gem "web-console"                   # Console on exception pages
  gem "pry", "~> 0.16" # Interactive Ruby shell
end

group :test do
  gem "capybara"                      # Browser testing
  gem "rails-controller-testing"      # Controller test helpers
  gem "rspec-html-matchers"           # HTML matchers for tests
  gem "selenium-webdriver", "~> 4.41" # Browser automation
  gem "shoulda-matchers", "~> 7.0" # One-liner tests for common patterns
  gem "webmock"                       # Mock HTTP requests in tests
end
