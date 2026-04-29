if Rails.env.development?
  if defined?(DevToolbar)
    DevToolbar.configure do |config|
      config.links = [
        { name: "Routes", path: "/rails/info/routes" },
        { name: "Database", path: "/rails/db" },
        { name: "ERD", path: "/erd" }
      ]
    end
  end
end
