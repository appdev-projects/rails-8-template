require "ipaddr"

# The client address a per-IP rate limit should count against.
#
# Render guarantees that the FIRST X-Forwarded-For field is the real client
# (later fields are its own proxies). Rails' remote_ip picks the LAST untrusted
# field instead, which on Render resolves to the edge proxy, so every visitor
# would share one throttle bucket. Outside Render, remote_ip is right.
module PerimeterClientIp
  UNKNOWN_RENDER_CLIENT = "unknown-render-client"

  def self.call(request, render: ENV["RENDER"] == "true")
    return ActionDispatch::Request.new(request.env).remote_ip.to_s unless render

    normalize(first_forwarded_address(request)) ||
      normalize(request.get_header("REMOTE_ADDR")) ||
      UNKNOWN_RENDER_CLIENT
  end

  def self.first_forwarded_address(request)
    request.get_header("HTTP_X_FORWARDED_FOR").to_s.split(",", 2).first
  end
  private_class_method :first_forwarded_address

  def self.normalize(raw_address)
    address = IPAddr.new(raw_address.to_s.strip)
    range = address.to_range
    return unless range.begin == range.end

    address.to_s
  rescue IPAddr::InvalidAddressError
    nil
  end
  private_class_method :normalize
end
