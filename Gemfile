source "https://rubygems.org"

# ==============================================================================
# Rails Core
# ==============================================================================
gem "rails", "~> 8.0.2"              # The web framework
gem "propshaft"                       # Asset pipeline (CSS, JS, images)
gem "pg", "~> 1.1"                    # PostgreSQL database adapter
gem "puma", ">= 5.0"                  # Web server
gem "importmap-rails"                 # JavaScript with ESM import maps
gem "turbo-rails"                     # Hotwire page acceleration (SPA-like)
gem "stimulus-rails"                  # Hotwire JavaScript framework

# ==============================================================================
# Rails 8 Solid Adapters (database-backed cache, jobs, websockets)
# ==============================================================================
gem "solid_cache"                     # Database-backed Rails.cache
gem "solid_queue"                     # Database-backed Active Job
gem "solid_cable"                     # Database-backed Action Cable

# ==============================================================================
# Performance & DevOps
# ==============================================================================
gem "bootsnap", require: false        # Faster boot times via caching
gem "thruster", require: false        # HTTP caching/compression for Puma

# ==============================================================================
# Windows-specific
# ==============================================================================
gem "tzinfo-data", platforms: %i[windows jruby]

# ==============================================================================
# Feature Gems - Authentication & Authorization
# ==============================================================================
gem "devise"                          # User authentication (sign up, sign in, etc.)

# ==============================================================================
# Feature Gems - File Uploads & Images
# ==============================================================================
gem "carrierwave"                     # File uploads
gem "cloudinary"                      # Cloud image storage and CDN

# ==============================================================================
# Feature Gems - Data & Search
# ==============================================================================
gem "faker"                           # Generate fake data for testing/seeds
gem "kaminari"                        # Pagination
gem "pagy"                            # Alternative pagination (faster)
gem "ransack"                         # Search and filtering

# ==============================================================================
# Feature Gems - Utilities
# ==============================================================================
gem "dotenv"                          # Load environment variables from .env
gem "http"                            # Simple HTTP client for APIs
gem "rollbar"                         # Error tracking in production
gem "appdev_support", "~> 0.2.1"      # Learning helpers (nicer error messages, etc.)

# ==============================================================================
# Feature Gems - AI
# ==============================================================================
gem "ai-chat", "~> 0.5.4"             # AI::Chat integration via OpenAI APIs

# ==============================================================================
# Development & Test - Debugging & Testing
# ==============================================================================
group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails", "~> 7.1.1"       # Testing framework
  gem "grade_runner", "~> 0.0.13"     # Automated grading
end

# ==============================================================================
# Development Only - Better Development Experience
# ==============================================================================
group :development do
  gem "amazing_print"                 # Pretty print Ruby objects in console
  gem "annotaterb"                    # Add schema info to model files
  gem "better_errors"                 # Better error pages with console
  gem "binding_of_caller"             # Required for better_errors console
  gem "dev_toolbar", "~> 2.1.0"       # Development toolbar
  gem "draft_generators", "~> 0.0.5"  # Beginner-friendly Rails generators
  gem "haikunator"                    # Generate random names (for databases)
  gem "htmlbeautifier"                # Format HTML/ERB files
  gem "pry-rails"                     # Better Rails console
  gem "rails_db", "~> 2.5.0"          # Database viewer in browser
  gem "rails-erd"                     # Generate ER diagrams
  gem "rufo"                          # Ruby code formatter
  gem "web-console"                   # Console on exception pages
end

# ==============================================================================
# Test Only - Testing Tools
# ==============================================================================
group :test do
  gem "capybara"                      # Browser testing
  gem "rails-controller-testing"      # Controller test helpers
  gem "rspec-html-matchers"           # HTML matchers for tests
  gem "selenium-webdriver", "~> 4.11.0" # Browser automation
  gem "shoulda-matchers", "~> 6.4"    # One-liner tests for common patterns
  gem "webmock"                       # Mock HTTP requests in tests
end
