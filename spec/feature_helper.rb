require 'spec_helper'
require 'capybara'
require 'capybara/dsl'
require 'webrick/https'
require 'rack/handler/webrick'
require 'ne_api_sdk_ruby/sample_app'
require 'selenium-webdriver'

CERT_PATH = File.expand_path('.ssl', File.dirname(__FILE__))

# http://cowjumpedoverthecommodore64.blogspot.jp/2013/09/if-your-website-runs-under-ssl-than.html
def run_ssl_server(app, port)
  opts = {
      :Port               => port,
      :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
      :DocumentRoot       => "/bin",
      :SSLEnable          => true,
      :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
      :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(File.join(CERT_PATH, "dev.crt.pem")).read),
      :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(File.join(CERT_PATH, "dev.pem")).read),
      :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
  }

  Rack::Handler::WEBrick.run(app, opts)
end

Capybara.server do |app, port|
  run_ssl_server(app, port)
end

Capybara.server_port = 8088
Capybara.app_host = "https://localhost:%d" % Capybara.server_port
Capybara.register_driver :selenium do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile.secure_ssl = false
  profile.assume_untrusted_certificate_issuer = false
  Capybara::Selenium::Driver.new(app, :browser => :firefox, profile: profile)
end
Capybara.default_driver = :selenium

RSpec.configure do |config|
  config.include Capybara::DSL
end