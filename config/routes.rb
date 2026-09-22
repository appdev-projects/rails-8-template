Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Render's health check (healthCheckPath in render.yaml) and the Docker HEALTHCHECK use it.
  get "up" => "rails/health#show", as: :rails_health_check

  # This is a blank app! Pick your first screen, build out the RCAV, and go from there. E.g.:
  # get("/your_first_screen", { :controller => "pages", :action => "first" })
end
