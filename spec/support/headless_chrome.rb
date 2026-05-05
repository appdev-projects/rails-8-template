# When chrome-headless-shell + chromedriver are present from bin/chromedriver_install
# (codespaces), pin them globally so EVERY Chrome-based driver picks them up --
# our custom :headless_chrome below, Rails' built-in :selenium_chrome_headless,
# anything. Without this Selenium Manager auto-downloads its own (full) Chrome
# and chromedriver into ~/.cache/selenium/, and the downloaded Chrome can't
# run on the codespace image (no GTK libs), so chromedriver dies at startup.
CHROME_BINARY = "/usr/local/bin/chrome-headless-shell"
CHROMEDRIVER_BINARY = "/usr/local/bin/chromedriver"
if File.exist?(CHROME_BINARY) && File.exist?(CHROMEDRIVER_BINARY)
  Selenium::WebDriver::Chrome.path = CHROME_BINARY
  Selenium::WebDriver::Chrome::Service.driver_path = CHROMEDRIVER_BINARY
end

# Register both our custom :headless_chrome AND override Capybara's built-in
# :selenium_chrome_headless (which Rails system tests use by default) with the
# flags Chrome needs to launch inside a container: no setuid sandbox available,
# limited /dev/shm. Without --no-sandbox / --disable-dev-shm-usage, Chrome exits
# immediately during session creation with "Chrome instance exited."
%i[headless_chrome selenium_chrome_headless].each do |driver_name|
  Capybara.register_driver driver_name do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless=new")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1400,1400")

    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: options
    )
  end
end

Capybara.default_max_wait_time = 3
