if defined?(AppdevSupport) && (Rails.env.development? || Rails.env.test?)
  AppdevSupport.config do |config|
    config.action_dispatch = true
    config.active_record   = true
    config.pryrc           = :minimal
  end

  AppdevSupport.init
end
