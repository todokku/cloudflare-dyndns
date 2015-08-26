require 'sinatra'

require 'ipaddr'
require 'httpclient'

X_AUTH_EMAIL = ENV["X-Auth-Email"]
X_AUTH_KEY = ENV["X-Auth-Key"]

raise "Invalid Credentials" unless X_AUTH_KEY.to_s.length > 0 && X_AUTH_EMAIL.to_s.length > 0

CLOUDFLARE_ZONE = ENV["CLOUDFLARE_ZONE"]
CLOUDFLARE_RECORD = ENV["CLOUDFLARE_RECORD"]

raise "Requires non-empty zone & record" unless CLOUDFLARE_ZONE.to_s.length > 0 && CLOUDFLARE_RECORD.to_s.length > 0

get '/' do
    local_auth = params["api-key"]
    halt 403, "Invalid api-key" unless local_auth == "6DCE6374-7C16-40E6-BEB2-3EABEF5A68D9"
    
    client_ip = IPAddr.new(request.ip)
    halt 400, "Must be IPv4 request address" unless client_ip.ipv4?
    
    HTTPClient.new.request("PATCH",
      "https://api.cloudflare.com/client/v4/zones/#{CLOUDFLARE_ZONE}/dns_records/#{CLOUDFLARE_RECORD}",
      :header => {
        'Content-Type' => 'application/json',
        'X-Auth-Email' => X_AUTH_EMAIL,
        'X-Auth-Key' => X_AUTH_KEY,
      },
      :body => "{ \"content\": \"#{client_ip.to_s}\" }",
      ).body
end
