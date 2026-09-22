# Guarded so this file is safe in a project whose Gemfile has no rollbar gem.
if Object.const_defined?("Rollbar")
  Rollbar.configure do |config|
    # Without configuration, Rollbar is enabled in all environments.
    # To disable in specific environments, set config.enabled=false.

    config.access_token = ENV["ROLLBAR_ACCESS_TOKEN"]

    # Only an explicitly keyed production app reports. Development, test, and a
    # production deploy without ROLLBAR_ACCESS_TOKEN stay dormant and make no
    # external requests at all.
    config.enabled = Rails.env.production? && config.access_token.present?

    # Filter non-actionable client errors out of the exception tracker.
    #
    # Bots constantly probe for paths that don't exist (POST /, OPTIONS /,
    # GET /app/etc/local.xml, HEAD /backup, path-traversal strings, malformed
    # multipart bodies, etc.). Rails handles all of these correctly — it returns
    # a 4xx — so they are not application bugs. At bot volume they generate
    # thousands of events that exhaust the error-tracking quota and bury real
    # errors. Drop them at the source.
    #
    # Tradeoff: this also silences a genuinely broken *internal* link (a typo'd
    # `link_to` that now 404s). That's acceptable — those surface in dev/test and
    # in user reports, and it's far cheaper than thousands of bot 404s.
    #
    # Note: we deliberately do NOT ignore ActiveRecord::RecordNotFound or
    # AbstractController::ActionNotFound — those can signal real bugs and stay
    # reportable.
    #
    # Rollbar matches these keys against `exception.class.name` exactly — there is
    # no walk up the ancestor chain (rollbar 3.x, notifier.rb#filtered_level) —
    # so each concrete class a bot can trigger must be listed by name.
    config.exception_level_filters.merge!(
      # No route matches [VERB] "/path" — bot probing for paths that don't exist.
      "ActionController::RoutingError" => "ignore",
      # Bots send garbage in the Accept header / URL (e.g. path-traversal probes
      # like "../../../etc/services", SQLi strings), which Rails rejects with a
      # 406 before routing.
      "ActionDispatch::Http::MimeNegotiation::InvalidType" => "ignore",
      # Malformed multipart bodies, bad parameter encoding, and invalid
      # query/path params. Rails wraps the underlying Rack/encoding error and
      # re-raises it under this single class, so the one key covers all three
      # ("Invalid request/query/path parameters: ...").
      "ActionController::BadRequest" => "ignore",
      # Malformed JSON (or other) request bodies. Unlike the encoding/query cases
      # above, this is NOT wrapped into ActionController::BadRequest, so it needs
      # its own key.
      "ActionDispatch::Http::Parameters::ParseError" => "ignore"
    )

    # If you run your staging application instance in production environment then
    # you'll want to override the environment reported by `Rails.env` with an
    # environment variable like this: `ROLLBAR_ENV=staging`.
    config.environment = ENV["ROLLBAR_ENV"].presence || Rails.env
  end
end
