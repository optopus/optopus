require 'rack/request'

class Rack::Request
  def trusted_proxy?(ip)
    ip =~ /^127\.0\.0\.1$|^::1$|^localhost$/i
  end
end

require './app'
map '/' do
  run Optopus::App
end
