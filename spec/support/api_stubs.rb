require "webmock/rspec"

path_to_file = Dir.pwd + "/spec/support/currency_symbols.json"
api_response = open(path_to_file).read.chomp
RSpec.configure do |config|
  config.before(:each) do
    stub_request(:get, /api.exchangerate.host\/list/).
      with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" }).
      to_return(status: 200, body: api_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /api.exchangerate.host\/list/).
      with(headers: { "Connection" => "close", "Host" => "api.exchangerate.host", "User-Agent" => "http.rb/#{HTTP::VERSION}" }).
      to_return(status: 200, body: api_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /prepend.me\/api.exchangerate.host\/list/).
      with(headers: { "Connection" => "close", "Host" => "prepend.me", "User-Agent" => "http.rb/#{HTTP::VERSION}" }).
      to_return(status: 200, body: api_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /api.exchangerate.host\/live/).
      with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" }).
      to_return(status: 200, body: api_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /api.exchangerate.host\/live/).
      with(headers: { "Connection" => "close", "Host" => "api.exchangerate.host", "User-Agent" => "http.rb/#{HTTP::VERSION}" }).
      to_return(status: 200, body: api_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /prepend.me\/api.exchangerate.host\/live/).
      with(headers: { "Connection" => "close", "Host" => "prepend.me", "User-Agent" => "http.rb/#{HTTP::VERSION}" }).
      to_return(status: 200, body: api_response, headers: { "Content-Type" => "application/json" })
  end
end

path_to_file = Dir.pwd + "/spec/support/cup_to_svc.json"
cup_to_svc = open(path_to_file).read.chomp
RSpec.configure do |config|
  config.before(:each) do
    stub_request(:get, /api.exchangerate.host\/convert/).
      with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" }).
      to_return(status: 200, body: cup_to_svc, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /api.exchangerate.host\/latest/).
      with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" }).
      to_return(status: 200, body: cup_to_svc, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /api.exchangerate.host\/convert/).
      with(headers: { "Connection" => "close", "Host" => "api.exchangerate.host", "User-Agent" => "http.rb/#{HTTP::VERSION}" }).
      to_return(status: 200, body: cup_to_svc, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /api.exchangerate.host\/latest/).
      with(headers: { "Connection" => "close", "Host" => "api.exchangerate.host", "User-Agent" => "http.rb/#{HTTP::VERSION}" }).
      to_return(status: 200, body: cup_to_svc, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /prepend.me\/api.exchangerate.host\/convert/).
      with(headers: { "Connection" => "close", "Host" => "prepend.me", "User-Agent" => "http.rb/#{HTTP::VERSION}" }).
      to_return(status: 200, body: cup_to_svc, headers: { "Content-Type" => "application/json" })

    stub_request(:get, /prepend.me\/api.exchangerate.host\/latest/).
      with(headers: { "Connection" => "close", "Host" => "prepend.me", "User-Agent" => "http.rb/#{HTTP::VERSION}" }).
      to_return(status: 200, body: cup_to_svc, headers: { "Content-Type" => "application/json" })
  end
end
