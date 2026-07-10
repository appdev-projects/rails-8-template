Rails.application.routes.draw do
  # Liveness only: 200 when Rails boots successfully, 500 otherwise.
  get "up" => "rails/health#show", as: :rails_health_check

  # This is a blank app! Pick your first screen, build out the RCAV, and go from there. E.g.:
  # get("/your_first_screen", { :controller => "pages", :action => "first" })
end
